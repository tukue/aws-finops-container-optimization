resource "aws_organizations_policy" "tagging_policy" {
  count = var.enable_org_policy ? 1 : 0

  name        = "${var.project_name}-tagging-policy"
  description = "Enforce consistent tagging for cost allocation"
  type        = "TAG_POLICY"

  content = jsonencode({
    tags = {
      Project = {
        tag_key = "Project"
        enforced_for = {
          "ec2:instance" = true
          "ec2:volume"   = true
          "s3:bucket"    = true
          "eks:cluster"  = true
          "ecs:cluster"  = true
          "ecs:service"  = true
        }
        tag_value = {
          "@@assign" = [var.project_name]
        }
      }
      Environment = {
        tag_key = "Environment"
        enforced_for = {
          "ec2:instance" = true
          "ec2:volume"   = true
          "s3:bucket"    = true
          "eks:cluster"  = true
          "ecs:cluster"  = true
          "ecs:service"  = true
        }
        tag_value = {
          "@@assign" = ["prod", "staging", "dev"]
        }
      }
      Team = {
        tag_key = "Team"
        enforced_for = {
          "ec2:instance" = true
          "ec2:volume"   = true
          "s3:bucket"    = true
          "eks:cluster"  = true
          "ecs:cluster"  = true
          "ecs:service"  = true
        }
        tag_value = {
          "@@assign" = var.allowed_teams
        }
      }
      CostCenter = {
        tag_key = "CostCenter"
        enforced_for = {
          "ec2:instance" = true
          "ec2:volume"   = true
          "s3:bucket"    = true
          "eks:cluster"  = true
          "ecs:cluster"  = true
          "ecs:service"  = true
        }
        tag_value = {
          "@@assign" = var.allowed_cost_centers
        }
      }
    }
  })
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-auto-tagger-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.default_tags
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-auto-tagger-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:CreateTags",
          "s3:PutBucketTagging",
          "eks:TagResource",
          "ecs:TagResource"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function for automated tagging
resource "aws_lambda_function" "auto_tagger" {
  filename      = "auto_tagger.zip"
  function_name = "${var.project_name}-auto-tagger"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  timeout       = 60

  environment {
    variables = {
      DEFAULT_TAGS = jsonencode(var.default_tags)
    }
  }

  tags = var.default_tags
}

resource "aws_cloudwatch_event_rule" "resource_creation" {
  name        = "${var.project_name}-resource-creation"
  description = "Trigger auto-tagging on resource creation"

  event_pattern = jsonencode({
    source      = ["aws.ec2", "aws.s3", "aws.eks", "aws.ecs"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ec2.amazonaws.com", "s3.amazonaws.com", "eks.amazonaws.com", "ecs.amazonaws.com"]
      eventName   = ["RunInstances", "CreateBucket", "CreateCluster", "CreateService"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.resource_creation.name
  target_id = "AutoTaggerTarget"
  arn       = aws_lambda_function.auto_tagger.arn
}
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_tagger.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.resource_creation.arn
}