################################################################################
# Cluster   
################################################################################

module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 5.2.0"

  cluster_name = "${local.workspace.project_name}-${local.workspace.environment_name}"     #"ecs-ec2"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }
  default_capacity_provider_use_fargate = false

  # tags = {
  #   Name = "${local.workspace.project_name}-${local.workspace.environment_name}"
  #   Project = "${local.workspace.project_name}-${local.workspace.environment_name}"
  #   Environment = "${local.workspace.environment_name}"
  #   Terraform   = "true"
  # }
  tags = local.tags
  
  autoscaling_capacity_providers = {
    # On-demand instances
    "ex-1-${local.workspace.project_name}-${local.workspace.environment_name}" = {
      auto_scaling_group_arn         = "${data.aws_autoscaling_groups.this.arns[0]}"   #"${module.autoscaling[ex-1].autoscaling_group_arn}"  #values(module.autoscaling[each.ex-1].autoscaling_group_arn)   #module.autoscaling["ex-1"].autoscaling_group_arn     #module.autoscaling["ex-1"].autoscaling_group_arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 90
      }

      default_capacity_provider_strategy = {
        weight = 80
        base   = 80
      }
    }
  }
}



locals {
  region = "us-east-1"
  name   = "demotest"
}


module "autoscaling" {
  #   depends_on = [
  #   module.ecs_cluster
  # ]
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.5"

  for_each = {
    # On-demand instances
    ex-1 = {
      name = module.ecs_cluster.name
      instance_type              = local.workspace.autoscaling.instance_type 
      use_mixed_instances_policy = false
      mixed_instances_policy     = {}
      user_data                  = <<-EOT
        #!/bin/bash
        yum update -y
        cd /tmp
        yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
        systemctl enable amazon-ssm-agent
        systemctl start amazon-ssm-agent

        cat <<'EOF' >> /etc/ecs/ecs.config
        ECS_CLUSTER=${local.workspace.project_name}-${local.workspace.environment_name}
        ECS_LOGLEVEL=debug
        ECS_ENABLE_TASK_IAM_ROLE=true
        EOF

      EOT
    }
  }

  name = "${local.workspace.project_name}-${local.workspace.environment_name}-${each.key}"        #"${local.name}-${each.key}"

  image_id      = local.workspace.autoscaling.image_id 
  instance_type = "t2.micro"

  security_groups                 = ["${module.autoscaling_sg.security_group_id}"] 
  user_data                       = base64encode(each.value.user_data)
  ignore_desired_capacity_changes = true

  create_iam_instance_profile = true
  iam_role_name               = "${local.workspace.project_name}-${local.workspace.environment_name}-asg_iam_role"   #local.name
  iam_role_description        = "ECS role for ${local.workspace.project_name}-${local.workspace.environment_name}-asg_iam_role"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier =  local.workspace.extra.subnet_ids         #module.vpc.private_subnets
  health_check_type   = "EC2"
  min_size            = "1"
  max_size            = "3"
  desired_capacity    = "1"

  # https://github.com/hashicorp/terraform-provider-aws/issues/12582
  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  # Required for  managed_termination_protection = "ENABLED"
  protect_from_scale_in = true

  # Spot instances
  use_mixed_instances_policy = each.value.use_mixed_instances_policy
  mixed_instances_policy     = each.value.mixed_instances_policy

  tags = local.tags
}

module "autoscaling_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${local.workspace.project_name}-${local.workspace.environment_name}-asg_sg"
  description = "Autoscaling group security group"
  vpc_id      = "vpc-09b0d790fb82b19fa" #module.vpc.vpc_id

  # computed_ingress_with_source_security_group_id = [
  #   {
  #     rule                     = "http-80-tcp"
  #     source_security_group_id = "sg-0bdb205b2598c3134"   #module.alb_sg.security_group_id
  #   },
  # ]
  # number_of_computed_ingress_with_source_security_group_id = 1

  # egress_rules = ["all-all"]

  tags = local.tags


  # ingress_cidr_blocks      = ["172.31.0.0/16"]
  # ingress_rules            = ["https-80-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = "49153"
      to_port     = "65535"
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "172.31.0.0/16"
    },
    # {
    #   rule        = "postgresql-tcp"
    #   cidr_blocks = "0.0.0.0/0"
    # },
  ]
  egress_rules = ["all-all"]
}

#   computed_ingress_with_source_security_group_id = [
#     {
#       rule                     = "http-80-tcp"
#       source_security_group_id = "sg-0dbaa5f7ef064318e"   #module.alb_sg.security_group_id
#     },
#   ]
#   number_of_computed_ingress_with_source_security_group_id = 1

#   egress_rules = ["all-all"]

#   tags = local.tags
# }