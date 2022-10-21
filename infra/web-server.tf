
locals {
  web_user_data = templatefile("${path.module}/scripts/web-server-init.sh", {
    consul_datacenter = "${var.consul_datacenter}"
    consul_acl_token  = "${random_uuid.bootstrap_token.result}"
    consul_gossip_key = "${random_id.gossip_encryption_key.b64_std}"
    consul_ca_cert    = "${tls_self_signed_cert.ca.cert_pem}"
    consul_ca_key     = "${tls_private_key.ca.private_key_pem}"
    consul_version    = "${var.consul_version}"
    consul_server_ip  = "${aws_instance.consul.private_ip}"
  })
}

resource "aws_instance" "web" {
  count = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name = aws_key_pair.webssh.key_name
  associate_public_ip_address = true
  user_data              = local.web_user_data
  tags = {
    Name = "${random_string.randomprefix.result}${var.name}-web-server"
    Env  = "web"
  }
}

resource "tls_private_key" "webssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "webssh" {
  public_key = tls_private_key.webssh.public_key_openssh
}

resource "null_resource" "webkey" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.webssh.private_key_pem}\" > ${aws_key_pair.webssh.key_name}.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pem"
  }

}