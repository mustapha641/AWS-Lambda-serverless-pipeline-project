module "s3" {
  source  = "./modules/s3"
  project = var.project
  env     = var.env
}

module "dynamodb" {
  source  = "./modules/dynamodb"
  project = var.project
  env     = var.env
}

module "messaging" {
  source      = "./modules/messaging"
  project     = var.project
  env         = var.env
  alert_email = var.alert_email
}

module "iam" {
  source                     = "./modules/iam"
  project                    = var.project
  env                        = var.env
  region                     = var.region
  account_id                 = var.account_id
  raw_bucket_arn             = module.s3.raw_bucket_arn
  processed_bucket_arn       = module.s3.processed_bucket_arn
  metadata_table_arn         = module.dynamodb.table_arn
  processing_done_topic_arn  = module.messaging.processing_done_topic_arn
}

module "lambda" {
  source                     = "./modules/lambda"
  project                    = var.project
  env                        = var.env
  raw_bucket_id              = module.s3.raw_bucket_id
  raw_bucket_arn             = module.s3.raw_bucket_arn
  processed_bucket_name      = module.s3.processed_bucket_name
  metadata_table_name        = module.dynamodb.table_name
  processing_done_topic_arn  = module.messaging.processing_done_topic_arn
  dlq_arn                    = module.messaging.dlq_arn
  processor_role_arn         = module.iam.processor_role_arn
  notifier_role_arn          = module.iam.notifier_role_arn
}
