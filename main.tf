module "security" {
  source = "./security"
  region = var.region
  availability_zone = var.availability_zone
  adminsport = var.adminsport
  
}

module "consul" {
  source = "./consul"
  region = var.region
  vpc_ip = module.security.vpc_ip.id
  availability_zone = var.availability_zone
  public_subnet = module.security.publicsubnetaz1.id
}
  
