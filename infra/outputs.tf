output "Consul_address" {
  value = "http://${aws_eip.consul.public_ip}:8500"
}

output "acl_bootstrap_token" {
  value = random_uuid.bootstrap_token.result
}

output "note_attention" {
  value = "It takes about 5-7 minutes to spin up the Fortigate in AWS, go grab a coffee"
}