
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

# data "template_file" "nia" {
#   template = file("./scripts/config.hcl.example")
#   vars = {
#     addr               = var.f5mgmtip
#     port               = "8443"
#     username           = "admin"
#     pwd                = random_string.password.result
#     consul             = aws_instance.consul.private_ip
#   }
# }
# resource "local_file" "nia-config" {
#   content  = data.template_file.nia.rendered
#   filename = "./cts-config/cts-config.hcl"
# }



resource "aws_instance" "consul" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.publicsubnetaz1.id
  vpc_security_group_ids = [aws_security_group.consul_allow.id]
  user_data              = file("./scripts/consul.sh")
  key_name               = aws_key_pair.consulsshkey.key_name
  associate_public_ip_address = true
  tags = {
    Name = "nia-consul"
    Env  = "consul"
  }
}




