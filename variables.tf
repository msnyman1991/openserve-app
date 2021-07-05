variable "instance_type" {
  description = "The EC2 instance type that the frontend will be deployed to."
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "The VPC to host the frontend on."
}

variable "environment" {
  description = "The name of the deployment environment (such as 'dev')"
}

variable "git_revision" {
  description = "The git commit hash to deploy."
}

variable "api_url" {
  description = "The fully qualified base URL of the API server. Example: https://api-dev.openverse.engineering"
}

variable "sentry_dsn" {
  description = "Sentry public DSN URL Found in https://sentry.io/settings/{account-name}/projects/{project-name}/keys/"
}

variable "social_sharing_enabled" {
  description = "Flag for enabling the image social sharing buttons"
}

variable "staging_environment" {}

variable "redis_url" {
  description = "URL of the Redis instance to use for registering IP for throttle whitelisting."
}

variable "enable_google_analytics" {
  description = "Flag to enable Google Analytics tracking of page views and user events"
}

variable "google_analytics_ua" {
  description = "The tracking code for Google Analytics"
}

variable "enable_internal_analytics" {
  description = "Flag to enable our internal usage analytics"
}

variable "container_port" {
  description = "The port where the Docker is exposed"
  default     = ""
}

variable "container_image" {
  description = "The name of the docker container image"
  default     = "openverse-frontend_web	"
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod\""
  default     = "poc"
}