#------------------Getting the values of my stored paramater for db identifier---------------------------------
data "aws_ssm_parameter" "gettingdbidentifier" {
  name = "/myapp/config/dbidentifier"
}

output "dbidentifier" {
  value = data.aws_ssm_parameter.gettingdbidentifier.value
}

#----------------------Creating SNS TOPIC for RDS--------------------------------------------------------------
resource "aws_sns_topic" "alert_topic" {
  name = "RDS_CPU_UTILIZATION_BY_AZEEZ"
}

#----------------------Creating those that would receive the notification(email)-------------------------------
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alert_topic.arn
  protocol  = "email"
  endpoint  = "stackcloud12@mkitconsulting.net" 
} 

#------------------------Creating Cloudwatch Alarm for RDS CPU USAGE-------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "RDS_CPU_Utilization_Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name        = "CPUUtilization"
  namespace          = "AWS/RDS"
  period             = 3600
  statistic          = "Average"
  threshold          = 80  
  alarm_description  = "Alarm when CPU utilization exceeds 80%"

  dimensions = {
    DBInstanceIdentifier = data.aws_ssm_parameter.gettingdbidentifier.value
  }

  alarm_actions = [aws_sns_topic.alert_topic.arn]  
}


#-------------------Getting the value for EFS ARN---------------------------------------------------------------

data "aws_ssm_parameter" "gettingefsarn" {
  name = "/myapp/config/efsarn"
}


output "efs_arn" {
  value = data.aws_ssm_parameter.gettingefsarn.value
}


#-------------------Getting loadbalnacer ARN----------------------------------------------------------
data "aws_ssm_parameter" "gettingloadbalancerarn" {
  name = "/myapp/config/loadbalancerarn"
}


output "loadbalancer_arn" {
  value = data.aws_ssm_parameter.gettingloadbalancerarn.value
}


#---------------------Getting Instance name fiorm ssm parameter store ---------------------------------
data "aws_ssm_parameter" "gettinginstancename" {
  name = "/myapp/config/instancename"
}


output "instance_name" {
  value = data.aws_ssm_parameter.gettinginstancename.value
}
