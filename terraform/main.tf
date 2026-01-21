provider "aws" {
  region = "ap-south-1" # Mumbai (Change if needed)
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# --- 1. Frontend: Public S3 Bucket ---
resource "aws_s3_bucket" "frontend" {
  bucket = "pawan-frontend-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "frontend_web" {
  bucket = aws_s3_bucket.frontend.id
  index_document { suffix = "index.html" }
}

# Unlock Public Access
resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.frontend.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid = "PublicRead", Effect = "Allow", Principal = "*", Action = "s3:GetObject",
      Resource = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

# --- 2. Backend: RDS Database (PostgreSQL) ---
resource "aws_db_instance" "default" {
  allocated_storage      = 20
  db_name                = "hybrid_db"
  engine                 = "postgres"
  engine_version         = "15.14"   # <--- Updated Version
  instance_class         = "db.t3.micro"
  username               = "pawan_admin"
  password               = "HybridPass2026!"
  publicly_accessible    = true
  skip_final_snapshot    = true
}

# --- 3. Storage: Private Backup Bucket ---
resource "aws_s3_bucket" "backups" {
  bucket = "pawan-backups-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

# --- Outputs ---
output "frontend_bucket" { value = aws_s3_bucket.frontend.bucket }
output "db_endpoint" { value = aws_db_instance.default.endpoint }
output "backup_bucket" { value = aws_s3_bucket.backups.bucket }
