output "vpc_id"
 value = module.security.vpc_id
}

output "fortigate_public_ip" {
  value = "https://${module.security.FGTPublicIP}:${var.adminsport}"
}
  
output "fortigate_username" {
  value = module.security.Username
}

output "fortigate_password" {
  value = module.security.password2
  sensitive = true
}

