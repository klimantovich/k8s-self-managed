#----------------------------------------
# Generate rsa key for cluster Nodes
#----------------------------------------
resource "aws_key_pair" "cluster" {
  key_name   = var.rsa_key_name
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "rsa-key" {
  content         = tls_private_key.rsa.private_key_pem
  filename        = "./${aws_key_pair.cluster.key_name}.pem"
  file_permission = "400"
}
