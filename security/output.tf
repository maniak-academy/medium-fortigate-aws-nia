
output "FGTPublicIP" {
  value = aws_eip.FGTPublicIP.public_ip
}

output "Username" {
  value = "admin"
}

output "password2" {
value = aws_instance.fgtvm.id
}
  
output "Password" {
  value = random_password.password.result
  sensitive = true
}



output "public_subnet_id" {
  value = aws_subnet.publicsubnetaz1.id
}

output "private_subnet_id" {
  value = aws_subnet.privatesubnetaz1.id
}

output "vpc_id" {
  value = aws_vpc.fgtvm-vpc.id
}