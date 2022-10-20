resource "random_string" "randomprefix" {
  length  = 4
  special = false
  upper   = false
  numeric = false
}

locals {
  consul_user_data = templatefile("${path.module}/scripts/consul-server-init.sh", {
    consul_datacenter = "${var.consul_datacenter}"
    consul_acl_token  = "${random_uuid.bootstrap_token.result}"
    consul_gossip_key = "${random_id.gossip_encryption_key.b64_std}"
    consul_ca_cert    = "${tls_self_signed_cert.ca.cert_pem}"
    consul_ca_key     = "${tls_private_key.ca.private_key_pem}"
    consul_version    = "${var.consul_version}"
    fortigate_password = "${var.fortigate_password}"
    fortigate_public_ip = "${var.fortigate_public_ip}"
  })
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "consul" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.consul.id]
  key_name = aws_key_pair.consussh.key_name
  user_data              = local.consul_user_data
  iam_instance_profile = aws_iam_instance_profile.consul.name
  tags = {
    Name = "${random_string.randomprefix.result}${var.name}-consul-server"
    Env  = "consul"
  }
}

resource "aws_eip" "consul" {
  instance = aws_instance.consul.id
  vpc      = true
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.consul.id
  allocation_id = aws_eip.consul.id
}


resource "tls_private_key" "consussh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "consussh" {
  public_key = tls_private_key.consussh.public_key_openssh
}

resource "null_resource" "key" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.consussh.private_key_pem}\" > ${aws_key_pair.consussh.key_name}.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pem"
  }

}