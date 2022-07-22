module "security" {
  source = "./security"
  region = var.region
  availability_zone = var.availability_zone
  adminsport = var.adminsport
  
}

# module "consul" {
#   source = "./consul"
#   region = var.region
#   availability_zone = var.availability_zone
#   private_subnet = module.security.privatesubnetaz1.id
# }
  
