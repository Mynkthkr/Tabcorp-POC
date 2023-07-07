module "ecs_service" {
      depends_on = [
    aws_lb_listener_rule.this
  ]
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "${local.workspace.ecs_service.name}-${local.workspace.environment_name}"
  cluster_arn = "${data.aws_ecs_cluster.test.arn}"               #local.workspace.container_definitions.cluster_arn 
  requires_compatibilities = ["EC2"]
  network_mode = "bridge"
  launch_type = "EC2"
  runtime_platform = "null"
  cpu    = "256"
  memory = "256"

  # Container definition(s)
  container_definitions = {

    ("${local.workspace.container_definitions.container_name}-${local.workspace.environment_name}") = {
    #   environment = {
    #   name  = "hello"
    #   value = "world"
    # }
      cpu       = "256"
      memory    = "256"
      essential = true
      image     = local.workspace.container_definitions.image 
      port_mappings = [
        {
          name          = local.workspace.container_definitions.name     #local.workspace.ecs_service.name
          containerPort = local.workspace.container_definitions.containerPort
          protocol      = local.workspace.container_definitions.protocol
        }
      ]

      # Example image used requires access to write to root filesystem
      readonly_root_filesystem = false
      #enable_cloudwatch_logging = false
      #memory_reservation = 100
    }
  }

  load_balancer = {
    service = {
      target_group_arn = "${aws_lb_target_group.this.arn}"          #"${data.aws_lb_target_group.test.id}"      #local.workspace.container_definitions.target_group_arn
      container_name   = "${local.workspace.container_definitions.container_name}-${local.workspace.environment_name}"   #local.workspace.load_balancer.container_name
      container_port   = local.workspace.load_balancer.container_port
    }
  }
  
  subnet_ids =  local.workspace.load_balancer.subnet_ids
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port   = "49153"
      to_port     = "65535"
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = "sg-0bdb205b2598c3134"
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Project = "${local.workspace.project_name}-${local.workspace.environment_name}"
    Environment = "${local.workspace.environment_name}"
    Terraform   = "true"
  }
}

resource "aws_lb_target_group" "this" {
  name     = "${local.workspace.ecs_service.name}-${local.workspace.environment_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-09b0d790fb82b19fa"        #pendingToBeIndata
  target_type          = "instance"
  load_balancing_algorithm_type = "least_outstanding_requests"

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  health_check {
    healthy_threshold   = 2
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }
  tags = {
    Project = "${local.workspace.project_name}-${local.workspace.environment_name}"
    Environment = "${local.workspace.environment_name}"
    Terraform   = "true"
  }
}

resource "aws_lb_listener_rule" "this" {
      depends_on = [
    aws_lb_target_group.this
  ]
  listener_arn = "${data.aws_lb_listener.this.arn}"   #"arn:aws:elasticloadbalancing:us-east-1:331851393000:listener/app/demo/14dee1e56f54f387/e5409a762f138f03"  #aws_lb_listener.front_end.arn
  priority     = 95    #pendingToBeInConfig

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.this.arn}"
  }

  condition {
    path_pattern {
      values = ["/nginx/*", "/nginx", "/nginx*"]
    }
  }

  # condition {
  #   host_header {
  #     values = ["exnginx.com"]
  #   }
  # }
}