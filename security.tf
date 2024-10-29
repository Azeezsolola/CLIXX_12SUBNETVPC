#----------------------Creating SNS TOPIC for RDS--------------------------------------------------------------
resource "aws_sns_topic" "alert_topic" {
  name = "RDS_CPU_UTILIZATION_BY_AZEEZ"
}

#----------------------Creating those that would receive the notification(email)-------------------------------
resource "aws_sns_topic_subscription" "email_subscription1" {
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
    DBInstanceIdentifier = aws_db_instance.restored_db.identifier
  }

  alarm_actions = [aws_sns_topic.alert_topic.arn]  
}


#----------------------Creating SNS Topic for load Balancer ------------------------------------------------------
resource "aws_sns_topic" "alert_topic2" {
  name = "LoadBalancer_Error_Message_BY_AZEEZ"
}


#--------------------------Creating subscription for who to recieve the notificartion-------------------
resource "aws_sns_topic_subscription" "email_subscription2" {
  topic_arn = aws_sns_topic.alert_topic2.arn
  protocol  = "email"
  endpoint  = "oloyedeifeoluwa21@gmail.com" 
} 


#-------------------Craeting Alarm for LoadBalacncer when theres an internal server error for any of the instances ---------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "internal_Server_Error_500"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name        = "HTTPCode_ELB_5XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = 300  
  statistic          = "Sum"
  threshold          = 20   

  dimensions = {
    LoadBalancer = aws_lb.test.dns_name  
  }

  alarm_description = "This alarm indicates there's a server internal error"
  
  
  alarm_actions = [
    aws_sns_topic.alert_topic2.arn
  ]
}



#------------------------Creating SNS topic for High cpu usage for instances in the autoscaling group-----------------------------
resource "aws_sns_topic" "alert_topic3" {
  name = "EC2_HIgh_CPUUsage_BY_AZEEZ"
}


#--------------------------Creating subscription for who to recieve the notificartion-------------------------------------------
resource "aws_sns_topic_subscription" "email_subscription3" {
  topic_arn = aws_sns_topic.alert_topic3.arn
  protocol  = "email"
  endpoint  = "oloyedeifeoluwa21@gmail.com" 
} 


#----------------------Alarm for High Instance CPU Usage--------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  alarm_name          = "HighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = 300  
  statistic          = "Average"
  threshold          = 80.0   

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.my_asg.name
  }

  alarm_description = "Alarm when CPU exceeds 80% for instances in the Auto Scaling Group"
  

  alarm_actions = [
    aws_sns_topic.alert_topic3.arn
  ]
}