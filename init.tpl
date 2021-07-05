#!/bin/bash

# Install node.js and other dependencies
curl --silent --location https://rpm.nodesource.com/setup_12.x | sudo bash -
sudo yum -y install gcc-c++ make nodejs git
wget http://download.redis.io/redis-stable.tar.gz && tar xvzf redis-stable.tar.gz && cd redis-stable && make && sudo cp src/redis-cli /usr/local/bin/ && sudo chmod 755 /usr/local/bin/redis-cli

# Create web root
mkdir -p /var/www/openverse-frontend
cd /var/www/openverse-frontend

# Write environment variables to disk
cat << EOF > /etc/environment
API_URL="${api_url}"
SOCIAL_SHARING="${social_sharing}"
ENABLE_GOOGLE_ANALYTICS="${enable_google_analytics}"
GOOGLE_ANALYTICS_UA="${google_analytics_ua}"
ENABLE_INTERNAL_ANALYTICS="${enable_internal_analytics}"
SENTRY_DSN="${sentry_dsn}"
PORT=8081
EOF

# Make sure these environment variables are exposed to Node + NPM.
source /etc/environment
export $(cut -d= -f1 /etc/environment)

# Add IP to rate limiting whitelist.
export IPV4_ADDRESS=`curl -s http://169.254.169.254/latest/meta-data/public-ipv4`
/usr/local/bin/redis-cli -h ${redis_url} sadd ip-whitelist $IPV4_ADDRESS

# Clone the frontend repository and copy to the web root
git clone https://github.com/wordpress/openverse-frontend.git
cd openverse-frontend
git checkout ${git_revision}
sudo cp -r ./* /var/www/openverse-frontend/

# Build the frontend application
cd /var/www/openverse-frontend
CYPRESS_INSTALL_BINARY=0 sudo npm install --unsafe-perm
npm run build

# Create version.json file (to serve statically later)
sudo cat << EOF > /var/www/openverse-frontend/version.json
{
  "release": "${git_revision}",
  "environment": "${staging_environment}"
}
EOF

# Install PM2 (https://pm2.keymetrics.io/) & create daemon
sudo npm install pm2@latest -g
pm2 startup --service-name frontend

# Create PM2 config file that runs the Nuxt binary in cluster mode
sudo cat << EOF > /var/www/openverse-frontend/ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'openverse-frontend',
      exec_mode: 'cluster',
      instances: 'max',
      script: './node_modules/nuxt/bin/nuxt.js',
      args: 'start'
    }
  ]
}
EOF

# Start PM2 with the config file, and save the pm2 processes
# (`pm2 save` automatacally configures our daemon to restart the app)
pm2 start
pm2 save

# Install and configure NGINX
sudo amazon-linux-extras install nginx1.12
sudo cat << EOF > /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format json_combined escape=json
      '{'
        '"time_local":"\$time_local",'
        '"remote_addr":"\$remote_addr",'
        '"remote_user":"\$remote_user",'
        '"request":"\$request",'
        '"status": "\$status",'
        '"body_bytes_sent":\$body_bytes_sent,'
        '"request_time":"\$request_time",'
        '"http_user_agent":"\$http_user_agent",'
        '"upstream_response_time":"\$upstream_response_time",'
        '"http_x_forwarded_for":"\$http_x_forwarded_for",'
        '"http_referer":"\$http_referer"'
      '}';

    access_log  /var/log/nginx/access.log  json_combined;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    # Compress large responses to save bandwidth and improve latency
    gzip on;
    gzip_min_length 860;
    gzip_vary on;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types application/json text/plain application/javascript;
    gzip_disable "MSIE [1-6]\.";

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=node:10m max_size=4g inactive=60m use_temp_path=off;
    server {
        listen          8080;
        root /var/www/openverse-frontend/dist;
        error_page 404 /index.html;
        index index.html;
        server_name     _;
        charset        utf-8;
        client_max_body_size 75M;

        location /version {
            default_type "application/json";
            alias /var/www/openverse-frontend/version.json;
        }

        location /healthcheck {
            default_type "text/plain";
            return 200 'healthy';
        }

        location / {
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header Host \$http_host;
            proxy_set_header X-NginX-Proxy true;
            proxy_cache node;
            proxy_pass http://localhost:8081/;
            add_header Cache-Control 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0';
            proxy_redirect off;
        }
    }
}
EOF
sudo systemctl start nginx
