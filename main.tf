module "security" {
  source            = "./security"
  region            = var.region
  availability_zone = var.availability_zone
  adminsport        = var.adminsport

}


module "infra" {
  source = "./infra"
  region = var.region
  consul_version = var.consul_version
  lb_ingress_ip = var.lb_ingress_ip
  public_subnet_id = module.security.public_subnet_id
  vpc_id = module.security.vpc_id
  fortigate_token = var.fortigate_token
  fortigate_public_ip = module.security.fw_public_ip
  depends_on = [
    module.security
  ]
}
