resource "tls_private_key" "sshkey" {
  algorithm = "RSA"
}

resource "aws_key_pair" "sshkey" {
  public_key = tls_private_key.sshkey.public_key_openssh
}

resource "null_resource" "key" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.sshkey.private_key_pem}\" > ${aws_key_pair.sshkey.key_name}.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pem"
  }

}