output "instance_id" {
  value = aws_instance.production.id
}

output "public_ip" {
  value = aws_instance.production.public_ip
}

output "website_url" {
  value = "http://${aws_instance.production.public_ip}"
}

output "backup_bucket" {
  value = aws_s3_bucket.backup.id
}

output "system_alarm" {
  value = aws_cloudwatch_metric_alarm.system_status.alarm_name
}

output "instance_alarm" {
  value = aws_cloudwatch_metric_alarm.instance_status.alarm_name
}
