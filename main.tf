provider "aws" {
  region = "eu-north-1"  # AWS region (change as needed)
}

resource "aws_instance" "app_server" {
  ami           = "ami-0d49bd8a094867c99" # Ubuntu 20.04 LTS
  instance_type = "t3.micro"
  key_name      = "automator"

  security_groups = [aws_security_group.app_sg.name]

  tags = {
    Name = "todo-server"
  }

  # Provisioner to create Ansible inventory file
  provisioner "local-exec" {
    command = <<EOT
      echo "[todo-server]" > inventory
      echo "${self.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/mukumbuta/Downloads/automator.pem" >> inventory
    EOT
  }

  # Ensure SSH is available before running Ansible
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for SSH access...'",
      "while ! nc -zv ${self.public_ip} 22; do sleep 5; done; echo 'SSH is available!'"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/mukumbuta/Downloads/automator.pem")
      host        = self.public_ip
    }
  }

  # Run Ansible playbook after the server is provisioned
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory ansible/playbook.yml"
  }

}

# Security group to allow SSH, HTTP, and HTTPS
resource "aws_security_group" "app_sg" {
  name        = "todos-sg-new"
  description = "Allow SSH, HTTP, and HTTPS"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP traffic
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTPS traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outgoing traffic
  }

}
