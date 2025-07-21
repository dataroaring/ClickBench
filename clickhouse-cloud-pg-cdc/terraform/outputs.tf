output "pg_endpoint" {
  value = aws_db_instance.flink_pg.endpoint
}

output "pg_username" {
  value = aws_db_instance.flink_pg.username
}

output "pg_password" {
  value = aws_db_instance.flink_pg.password
  sensitive = false
}

output "flink_master_public_ip" {
  value = aws_instance.flink_master.public_ip
}