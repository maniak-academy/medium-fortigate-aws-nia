output "consulip" {
    value = aws_instance.consul.associate_public_ip_address.id
}