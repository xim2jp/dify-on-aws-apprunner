output "service_url" {
  value = aws_apprunner_service.main.service_url
}

output "service_arn" {
  value = aws_apprunner_service.main.arn
}

output "service_id" {
  value = aws_apprunner_service.main.service_id
}

output "vpc_connector_arn" {
  value = aws_apprunner_vpc_connector.main.arn
}
