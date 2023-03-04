resource "null_resource" "ssh_target" {

  triggers = {

    user        = var.ssh_user
    host        = var.ssh_host
    private_key = var.ssh_key

    dependencies = var.dependencies

  }

  connection {

    type        = "ssh"
    user        = self.triggers.user
    host        = self.triggers.host
    private_key = file(self.triggers.private_key)

  }



  provisioner "file" {
    source      = "./modules/install_dependencies/configure.sh"
    destination = "/tmp/configure.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/configure.sh",
      "sudo /tmp/configure.sh",
      "sudo apt update -y",
      "sudo apt install -y  ${var.dependencies}"
    ]
  }


  provisioner "remote-exec" {

    when = destroy

    inline = [
      "sudo apt purge -y  ${self.triggers.dependencies}",
      "sudo apt autoremove -y"
    ]
  }

}
