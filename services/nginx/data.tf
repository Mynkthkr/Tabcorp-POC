# data "aws_lb_target_group" "test" {
#   tags = {
#       Project = "${local.workspace.project_name}-${local.workspace.environment_name}"
#     }
# }

data "aws_ecs_cluster" "test" {
  cluster_name = "${local.workspace.project_name}-${local.workspace.environment_name}"
  # tags = {
  #     Project = "EcsEc2"
  #   }
}
data "aws_lb" "test" {
  name = "${local.workspace.project_name}-${local.workspace.environment_name}-alb"
}
data "aws_lb_listener" "this" {
  load_balancer_arn = data.aws_lb.test.arn
  tags = {
      Project = "${local.workspace.project_name}-${local.workspace.environment_name}"
    }
  port              = 80
}