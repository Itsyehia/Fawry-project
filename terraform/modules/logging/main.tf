

resource "aws_cloudwatch_log_group" "vpc_logs" {
  name = "poc-${var.env}-logs"
  retention_in_days = 7

  tags = {
    Name = "poc-${var.env}-logs"
  }
}

resource "aws_s3_bucket" "vpc_logs" {
  bucket = "poc-${var.env}-vpc-logs-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name = "poc-${var.env}-log-bucket"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_flow_log" "to_cloudwatch" {
  log_destination_type = "cloud-watch-logs"
  log_group_name       = aws_cloudwatch_log_group.vpc_logs.name
  traffic_type         = "ALL"
  vpc_id               = var.vpc_id

  iam_role_arn = aws_iam_role.flow_logs.arn
}

resource "aws_flow_log" "to_s3" {
  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.vpc_logs.arn
  traffic_type         = "ALL"
  vpc_id               = var.vpc_id

 
}

resource "aws_iam_role" "flow_logs" {
  name = "poc-${var.env}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs_policy" {
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.vpc_logs.arn}/*"
      }
    ]
  })
}
