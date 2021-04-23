aws_region             = "eu-west-2"
az_count               = 2
ecs_fargate_version    = "1.4.0"
webapp_count           = 1
webapp_fargate_cpu     = 256
webapp_fargate_memory  = 512
service_count          = 1
service_fargate_cpu    = 256
service_fargate_memory = 512
db_storage             = 20
db_max_storage         = 20
db_delete_protection   = true
db_instance_class      = "db.t3.micro"
db_storage_encrypted   = true
db_skip_final_snapshot = false