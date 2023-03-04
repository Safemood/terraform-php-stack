resource "null_resource" "install_node" {

  triggers = {

    user        = var.ssh_user
    host        = var.ssh_host
    private_key = var.ssh_key

  }

  connection {

    type        = "ssh"
    user        = self.triggers.user
    host        = self.triggers.host
    private_key = file(self.triggers.private_key)

  }

  provisioner "remote-exec" {

    inline = [
      "sudo apt-get update -y",
      "curl -sL https://deb.nodesource.com/setup_${var.node_version}.x | sudo -E bash -",
      "sudo apt-get install -y nodejs"
    ]

  }


  provisioner "remote-exec" {

    when = destroy

    inline = [
      "sudo apt-get -y purge nodejs",
      "sudo apt autoremove -y"
    ]
  }

}
