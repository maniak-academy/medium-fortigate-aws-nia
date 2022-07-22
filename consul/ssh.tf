resource "tls_private_key" "consulsshkey" {
  algorithm = "RSA"
}

resource "aws_key_pair" "consulsshkey" {
  public_key = tls_private_key.consulsshkey.public_key_openssh
}

resource "null_resource" "key" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.consulsshkey.private_key_pem}\" > ${aws_key_pair.consulsshkey.key_name}.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 *.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f *.pem"
  }

}