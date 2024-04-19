resource "aws_security_group" "jumphost" {
  name        = "Jumphost Ports"
  description = "Firewall rules for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["217.28.48.78/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "jumphost" {
  source = "../aws-ec2"

  ec2_ami                         = var.instances_ami
  ec2_instance_type               = "t2.nano"
  ec2_associate_public_ip_address = true

  ec2_subnet_id              = var.public_subnet_ids[0]
  ec2_vpc_security_group_ids = [aws_security_group.jumphost.id]
  ec2_key_name               = aws_key_pair.cluster.key_name

  ec2_instance_tags = {
    Name = "jumphost"
  }

  # depends_on = [module.control-plane-node]
}
