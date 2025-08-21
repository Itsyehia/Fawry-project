resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "poc-${var.env}-key"
  public_key = tls_private_key.this.public_key_openssh

  lifecycle {
    ignore_changes = [public_key]
    create_before_destroy = true
  }
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.this.private_key_pem
  filename = "${path.module}/poc-${var.env}-key.pem"
  file_permission = "0600"
}

resource "aws_security_group" "this" {
  name        = "poc-${var.env}-sg"
  vpc_id      = var.vpc_id
  description = "Allow SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Kubernetes API traffic between instances
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }

  # Allow public access to Kubernetes API (for testing)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow public access to Kubernetes API"
  }

  # Allow public access to NodePort 30080 (portfolio app)
  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow public access to portfolio app NodePort"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "poc-${var.env}-sg"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "this" {
  count         = var.instance_count
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  subnet_id     = element(var.subnet_ids, count.index)
  vpc_security_group_ids = [aws_security_group.this.id]
  key_name      = aws_key_pair.this.key_name
  associate_public_ip_address = true

  tags = {
    Name = "poc-${var.env}-instance${count.index + 1}"
    Role = count.index == 0 ? "controlplane" : "worker"
  }
}
