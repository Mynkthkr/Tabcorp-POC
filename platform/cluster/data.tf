# data "aws_autoscaling_groups" "this" {
#   name = "${local.workspace.project_name}-${local.workspace.environment_name}-ex-1"
# }
data "aws_autoscaling_groups" "this" {
    depends_on = [
    module.autoscaling
  ]
  filter {
    name   = "key"
    values = ["Name"]
  }

  filter {
    name   = "value"
    values = ["${local.workspace.project_name}-${local.workspace.environment_name}-ex-1"]
  }
}
