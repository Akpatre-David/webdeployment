terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


resource "aws_security_group" "web_sg" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_key_pair" "deploymentKey" {
  key_name   = "portfolio-key"
  public_key = file("/home/davidubuntu/Desktop/porfoliodeploy/deploymentKey.pub")
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = "ami-0ecb62995f68bb549" 
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name                = aws_key_pair.deploymentKey.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu
              docker run -d --restart unless-stopped -p 80:80 17csc028/portfolio
              EOF

  tags = {
    Name = "PortfolioWebServer"
  }
}


output "public_ip" {
  value = aws_instance.web.public_ip
}
