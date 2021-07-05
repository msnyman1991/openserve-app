#ECS cluster
resource "aws_ecs_cluster" "ecs-cluster" {
  name = "ecs-cluster"
}

#ECS tasks
resource "aws_ecs_task_definition" "ecs-cluster-task" {
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs-task-execution-role.arn
  task_role_arn            = aws_iam_role.ecs-task-role.arn
  container_definitions = jsonencode([
    {
      name      = var.container_image
      image     = var.container_image
      essential = true
      environment = var.container_environment
      portMappings = [
        {
            protocol      = "tcp"
            containerPort = var.container_port
            hostPort      = var.container_port
        }
      ]
    }
  ])
}

#ECS service
resource "aws_ecs_service" "ecs-service" {
  name                               = "ecs-service"
  cluster                            = aws_ecs_cluster.ecs-cluster.id
  task_definition                    = aws_ecs_task_definition.ecs-cluster-task.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
 
 network_configuration {
   security_groups  = sg.aws_security_group.ecs-tasks-sg.id
   subnets          = module.vpc.private_subnets
   assign_public_ip = false
 }
 
 load_balancer {
   target_group_arn = aws_lb_target_group.alb-target-group.arn
   container_name   = var.container_image
   container_port   = var.container_port
 }
 
 lifecycle {
   ignore_changes = [task_definition, desired_count]
 }
}

