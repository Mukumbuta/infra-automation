# Provisioner to create Ansible inventory file
resource "null_resource" "ansible_inventory" {
  provisioner "local-exec" {
    command = <<EOT
      echo "[todo-server]" > ../ansible/inventory
      echo "${aws_instance.app_server.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/mukumbuta/Downloads/automator.pem" >> ../ansible/inventory
    EOT
  }

  depends_on = [aws_instance.app_server] # Ensuring dependency
}

# Ensure SSH is available before running Ansible
resource "null_resource" "wait_for_ssh" {
  provisioner "remote-exec" {
    inline = [
      "while ! nc -zv ${aws_instance.app_server.public_ip} 22; do sleep 5; done"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/mukumbuta/Downloads/automator.pem")
      host        = aws_instance.app_server.public_ip
    }
  }

  depends_on = [aws_instance.app_server]
}

# Run Ansible playbook after the server is provisioned
resource "null_resource" "run_ansible" {
  depends_on = [null_resource.wait_for_ssh, null_resource.ansible_inventory]

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ../ansible/inventory ../ansible/playbook.yml"
  }
}
