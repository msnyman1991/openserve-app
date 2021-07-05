#ECR repository
resource "aws_ecr_repository" "ecs-ecr" {
  name                 = "ecs-ecr"
  image_tag_mutability = "MUTABLE"
}

#ECR lifecycle policy
resource "aws_ecr_lifecycle_policy" "ecs-ecr-lfc-policy" {
  repository = aws_ecr_repository.ecs-ecr.name
 
  policy = jsonencode({
   rules = [{
     rulePriority = 1
     description  = "keep last 10 images"
     action       = {
       type = "expire"
     }
     selection     = {
       tagStatus   = "any"
       countType   = "imageCountMoreThan"
       countNumber = 10
     }
   }]
  })
}