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
      "ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts",
      "sudo sed -i 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/g' /etc/ssh/ssh_config",
      "sudo rm -rf /tmp/${var.domain_name}",
      "git clone ${var.git_repo} /tmp/${var.domain_name}",
      "sudo rm -rf /var/www/${var.domain_name}",
      "sudo mv -f /tmp/${var.domain_name} /var/www/"
    ]
  }

  provisioner "file" {
    content = templatefile("./modules/setup_app/.env.tftpl", {
      APP_NAME    = var.domain_name
      APP_ENV     = var.app_env,
      APP_DEBUG   = var.app_debug,
      APP_URL     = "${var.scheme}://${var.domain_name}",
      DB_HOST     = var.db_host,
      DB_PORT     = var.db_port,
      DB_DATABASE = var.db_name,
      DB_USERNAME = var.db_user,
      DB_PASSWORD = var.db_password,
      # VITE_PUSHER_APP_KEY     = "${PUSHER_APP_KEY}"
      # VITE_PUSHER_HOST        = "${PUSHER_HOST}"
      # VITE_PUSHER_PORT        = "${PUSHER_PORT}"
      # VITE_PUSHER_SCHEME      = "${PUSHER_SCHEME}"
      # VITE_PUSHER_APP_CLUSTER = "${PUSHER_APP_CLUSTER}"
    })
    destination = "/tmp/.env"
  }


  provisioner "remote-exec" {

    inline = concat(
      [
        "sudo mv /tmp/.env /var/www/${var.domain_name}/.env",
        "cd /var/www/${var.domain_name}",
      ],
      var.installation_steps
    )

  }


}
