resource "null_resource" "ssh_target" {


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

  provisioner "file" {
    source      = "./modules/install_mysql/create_db.sh"
    destination = "/tmp/create_db.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create_db.sh",
      // order is important 
      "sudo /tmp/create_db.sh ${var.mysql_root_password} ${var.db_name} ${var.db_user} ${var.db_password}",
    ]
  }


  provisioner "remote-exec" {

    when       = destroy
    on_failure = continue

    inline = [
      "sudo apt purge -y mysql*",
      "sudo apt autoremove -y"
    ]
  }

}



