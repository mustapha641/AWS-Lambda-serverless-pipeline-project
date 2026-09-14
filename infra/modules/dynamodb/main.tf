resource "aws_dynamodb_table" "image_metadata" {
  name         = "${var.project}-image-metadata-${var.env}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "image_id"

  attribute {
    name = "image_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }
}
