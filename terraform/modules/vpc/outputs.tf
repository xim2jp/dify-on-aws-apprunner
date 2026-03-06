output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "apprunner_security_group_id" {
  value = aws_security_group.apprunner.id
}

output "database_security_group_id" {
  value = aws_security_group.database.id
}
