resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "poc-${var.env}-vpc"
  }
}

resource "aws_subnet" "public" {
  count = length(var.subnet_cidrs)
  vpc_id = aws_vpc.this.id
  cidr_block = var.subnet_cidrs[count.index]
  availability_zone = "eu-west-1a"

  tags = {
    Name = "poc-${var.env}-subnet${count.index + 1}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "poc-${var.env}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "poc-${var.env}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "k3s" {
  name        = "poc-${var.env}-k3s-sg"
  description = "Allow SSH, HTTP, HTTPS, and NodePort for K3s"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Flask application port
  ingress {
    from_port   = 5002
    to_port     = 5002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow access to Flask app"
  }
  # NodePort range for Kubernetes services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow access to Kubernetes NodePort services"
  }
  # Allow K3s internal communication
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Allow internal cluster communication"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "poc-${var.env}-k3s-sg"
  }
}
