resource "null_resource" "ssh_target" {

  triggers = {

    user        = var.ssh_user
    host        = var.ssh_host
    private_key = var.ssh_key

    php_version = var.php_version

  }

  connection {

    type        = "ssh"
    user        = self.triggers.user
    host        = self.triggers.host
    private_key = file(self.triggers.private_key)

  }

  provisioner "file" {
    source      = "./modules/install_php/setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh ${var.php_version}",
    ]
  }

  provisioner "file" {
    source      = "./modules/install_php/php.ini"
    destination = "/tmp/php.ini"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/php.ini /etc/php/${var.php_version}/cli/conf.d/php.ini",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      # Composer
      "curl -sS https://getcomposer.org/installer | php",
      "sudo mv composer.phar /usr/local/bin/composer",
      "sudo chmod +x /usr/local/bin/composer",
    ]
  }


  provisioner "remote-exec" {

    when = destroy

    inline = [
      "sudo apt purge -y php* composer",
      "sudo apt autoremove -y"
    ]
  }

}
