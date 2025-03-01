provider "aws" {
  region = "eu-north-1"
}

resource "aws_instance" "app_server" {
  ami             = "ami-0d49bd8a094867c99"
  instance_type   = var.instance_type
  key_name        = var.key_name
  security_groups = [aws_security_group.app_sg.name]

  tags = {
    Name = "todo-server"
  }
}
