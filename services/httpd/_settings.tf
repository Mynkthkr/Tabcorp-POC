

# locals {
#   #env       = yamldecode(file("${path.module}/config.yml"))
#  # common    = local.env["common"]
#   env_space = yamldecode(file("config.yml"))
#   workspace = local.env_space["workspace"][terraform.workspace]

#   project_name_prefix = "${local.workspace.environment_name}"

#   tags = {
#     Project = "${local.workspace.project_name}-${local.workspace.environment_name}"
#     Environment = local.workspace.environment_name
#     Terraform   = "true"
#   }
# }




locals {
  env       = yamldecode(file("${path.module}/config.yml"))
  common    = local.env["common"]
  env_space = yamldecode(file("${path.module}/config-${terraform.workspace}.yml"))  #yamldecode(file("config.yml"))
  workspace = local.env_space["workspaces"][terraform.workspace]

  project_name_prefix = "${local.workspace.environment_name}-${local.workspace.project_name}"

  tags = {
    Project = "${local.workspace.project_name}-${local.workspace.environment_name}"
    Environment = local.workspace.environment_name
    Terraform   = "true"
  }
}


terraform {
  required_version = ">= 1.3.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "5.7.0"    #"4.23.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.10.0"
    }
    mysql = {
      source = "petoju/mysql"
      version = "3.0.27"
    }
    rabbitmq = {
      source = "cyrilgdn/rabbitmq"
      version = "1.7.0"
    }
  }
}
