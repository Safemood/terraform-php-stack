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

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -qq >/dev/null",
      "sudo apt-get install -y nginx",
    ]
  }

  provisioner "file" {
    content = templatefile("./modules/install_nginx/default.tftpl", {
      domain_name = var.domain_name,
      php_version = var.php_version
    })
    destination = "/tmp/default"

  }

  provisioner "remote-exec" {
    inline = [
      # nginx configured
      "sudo rm /etc/nginx/sites-available/default",
      "sudo rm /etc/nginx/sites-enabled/default",
      "sudo mv /tmp/default  /etc/nginx/sites-available/${var.domain_name}",
      "sudo ln -s /etc/nginx/sites-available/${var.domain_name} /etc/nginx/sites-enabled/",
      "sudo nginx -t && sudo nginx -s reload",
    ]
  }

  provisioner "remote-exec" {

    when = destroy

    inline = [
      "sudo apt-get -y purge nginx nginx-common",
      "sudo apt autoremove -y"
    ]
  }
}


