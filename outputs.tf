output "fortigate_public_ip" {
  value = "https://${module.security.fw_public_ip}:${var.adminsport}"
}

output "fortigate_username" {
  value = module.security.Username
}

output "fortigate_password" {
  value     = module.security.Password
  sensitive = true
}

output "consul_public_ip" {
  value = module.infra.Consul_address
}

output "consul_bootstrap_token" {
  value = module.infra.acl_bootstrap_token
}

output "ssh-foritgate-firewall" {
  value = "ssh -i ${module.security.fortigate_ssh_key} admin@${module.security.fw_public_ip}"
}
output "attention" {
  value = "It takes about 5-7 minutes to spin up the Fortigate in AWS, go grab a coffee"
}