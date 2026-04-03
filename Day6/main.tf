provider "aws" {
    region = var.region
}

#S3 bucket to store terraform state
resource "aws_s3_bucket" "day6_bucket" {
    bucket = var.day6-s3-bucket

    lifecycle {
        prevent_destroy = true
    }


    tags = {
        Name = "wamwea"
    }
}


#Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "day6_s3_versioning" {
    bucket = aws_s3_bucket.day6_bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}


# Enable encryption on the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "day6_s3_encription" {
    bucket = aws_s3_bucket.day6_bucket.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}



#Block all pubic access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "aws_s3_bucket_public_access_block" {
    bucket = aws_s3_bucket.day6_bucket.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}


#DynamoDB table fors terraform state locking
resource "aws_dynamodb_table" "day6_dynamodb_table" {
    name = "wamwea_db"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }

    tags = {
        Name = "wamwea"
    }
}


#outputs
output "s3_bucket_name" {
    value = aws_s3_bucket.day6_bucket.bucket
    description = "The name of the S3 bucket for terraform state"
}

output "dynamodb_table_name" {
    value = aws_dynamodb_table.day6_dynamodb_table.name
    description = "The name of the DynamoDB table for terraform state locking"
}