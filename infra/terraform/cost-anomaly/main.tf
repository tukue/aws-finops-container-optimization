resource "aws_ce_anomaly_monitor" "service_monitor" {
  name              = "AWSServiceMonitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_sns_topic" "cost_anomalies" {
  name = "aws-cost-anomaly-alerts"
}

resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.cost_anomalies.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSAnomalyDetectionSNSPublishing"
        Effect = "Allow"
        Principal = {
          Service = "costalerts.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.cost_anomalies.arn
      }
    ]
  })
}

resource "aws_ce_anomaly_subscription" "email_subscription" {
  name      = "DailyAnomalySubscription"
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.cost_anomalies.arn
  }

  # Optional: Add email subscriber if variable is provided
  # subscriber {
  #   type    = "EMAIL"
  #   address = var.alert_email
  # }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
      values        = ["20"] # Alert if anomaly impact is > 20%
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
}

# Placeholder for Lambda integration
# To complete the Slack integration, you would trigger a Lambda from this SNS topic.
