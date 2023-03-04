variable "ssh_host" {}
variable "ssh_user" {}
variable "ssh_key" {}
variable "php_version" {}
variable "node_version" {}
variable "domain_name" {}
variable "scheme" {}
variable "git_repo" {}
variable "webmaster_email" {}
variable "mysql_root_password" {}
variable "app_env" {}
variable "app_debug" {}
variable "db_connexion" {}
variable "db_host" {}
variable "db_port" {}
variable "db_user" {}
variable "db_name" {}
variable "db_password" {}
variable "stack_modules" {}
variable "system_dependencies" {}
variable "installation_steps" {}



module "install_dependencies" {

  count = contains(var.stack_modules, "dependencies") ? 1 : 0

  source = "./modules/install_dependencies"

  ssh_host = var.ssh_host
  ssh_user = var.ssh_user
  ssh_key  = var.ssh_key

  dependencies = "git tmux vim zip unzip htop fail2ban"

}

module "install_node" {

  count = contains(var.stack_modules, "node") ? 1 : 0

  source = "./modules/install_node"

  ssh_host = var.ssh_host
  ssh_user = var.ssh_user
  ssh_key  = var.ssh_key

  node_version = var.node_version

  depends_on = [
    module.install_dependencies,
  ]

}

module "install_php" {

  count = contains(var.stack_modules, "php") ? 1 : 0

  source = "./modules/install_php"

  ssh_host    = var.ssh_host
  ssh_user    = var.ssh_user
  ssh_key     = var.ssh_key
  php_version = var.php_version

  depends_on = [
    module.install_dependencies,
  ]
}



module "install_nginx" {

  count = contains(var.stack_modules, "nginx") ? 1 : 0

  source = "./modules/install_nginx"

  ssh_host = var.ssh_host
  ssh_user = var.ssh_user
  ssh_key  = var.ssh_key

  domain_name = var.domain_name
  php_version = var.php_version


  depends_on = [
    module.install_dependencies,
    module.install_php,
  ]
}




module "install_mysql" {

  count = contains(var.stack_modules, "mysql") ? 1 : 0

  source = "./modules/install_mysql"


  ssh_host = var.ssh_host
  ssh_user = var.ssh_user
  ssh_key  = var.ssh_key

  mysql_root_password = var.mysql_root_password

  db_host     = var.db_host
  db_port     = var.db_port
  db_user     = var.db_user
  db_name     = var.db_name
  db_password = var.db_password




  depends_on = [
    module.install_dependencies,
    module.install_php,
    module.install_nginx
  ]
}



module "setup_app" {

  count = contains(var.stack_modules, "app") ? 1 : 0


  source = "./modules/setup_app"

  ssh_host     = var.ssh_host
  ssh_user     = var.ssh_user
  ssh_key      = var.ssh_key
  domain_name  = var.domain_name
  scheme       = var.scheme
  git_repo     = var.git_repo
  app_env      = var.app_env
  app_debug    = var.app_debug
  db_connexion = var.db_connexion
  db_host      = var.db_host
  db_port      = var.db_port
  db_name      = var.db_name
  db_user      = var.db_user
  db_password  = var.db_password

  installation_steps = var.installation_steps


  depends_on = [
    module.install_dependencies,
    module.install_node,
    module.install_php,
    module.install_nginx
  ]


}

resource "null_resource" "ssl_certificates" {
  count = var.scheme == "https" ? 1 : 0

  connection {
    type        = "ssh"
    user        = var.ssh_user
    host        = var.ssh_host
    private_key = file(var.ssh_key)
  }

  provisioner "remote-exec" {

    inline = [
      # ssl configured && reload nginx
      "sudo ufw allow https",
      "sudo apt-get install -y python3-certbot-nginx",
      "sudo certbot --nginx --non-interactive --agree-tos --domains ${var.domain_name} --email ${var.webmaster_email} --no-eff-email --redirect",
      "sudo certbot renew --dry-run",
      "sudo nginx -t && sudo nginx -s reload",
    ]

  }

  depends_on = [
    module.install_dependencies,
    module.install_php,
    module.install_nginx,
    module.install_mysql,
    module.setup_app
  ]


}



