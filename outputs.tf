output "fortigate_public_ip" {
  value = "https://${module.security.fw_public_ip}:${var.adminsport}"
}

output "fortigate_username" {
  value = module.security.Username
}

output "fortigate_password" {
  value     = module.security.password2
  sensitive = true
}

output "consul_public_ip" {
  value = module.infra.Consul_address
}

output "consul_bootstrap_token" {
  value = module.infra.acl_bootstrap_token
}

