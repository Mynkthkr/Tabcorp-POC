module "db" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-rds.git"

  identifier = "demodb"

  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.m5.xlarge"
  allocated_storage = 5

  db_name  = local.workspace["rds"]["db_name"]
  username = local.workspace["rds"]["username"]
  port     = local.workspace["rds"]["port"]
  password  = local.workspace["rds"]["password"]

  iam_database_authentication_enabled = true

  vpc_security_group_ids = ["sg-0065ec72bb70f24bf"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  monitoring_interval = "30"
  monitoring_role_name = "MyRDSMonitoringRole"
  create_monitoring_role = true

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = ["subnet-0dd96741b19ec4c20", "subnet-0882d12e9929ce102"]

  # DB parameter group
  family = local.workspace.rds.family
  # DB option group
  major_engine_version = "5.7"

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name = "character_set_client"
      value = "utf8mb4"
    },
    {
      name = "character_set_server"
      value = "utf8mb4"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}



module "store_write" {
  source  = "cloudposse/ssm-parameter-store/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"

  parameter_write = [
    {
      name        = "db_name"
      value       = local.workspace["rds"]["db_name"]
      type        = "String"
      overwrite   = "true"
      description = "Production database master password"
    },
        {
      name        = "password"
      value       = local.workspace["rds"]["password"]
      type        = "String"
      overwrite   = "true"
      description = "Production database master password"
    },
        {
      name        = "username"
      value       = local.workspace["rds"]["username"]
      type        = "String"
      overwrite   = "true"
      description = "Production database master password"
    }

  ]

  tags = {
    ManagedBy = "Terraform"
  }
}