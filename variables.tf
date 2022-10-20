variable "region" {
  default = "us-east-1"
  type    = string

}

// Availability zones for the region
variable "availability_zone" {
  default = "us-east-1a"
  type    = string

}

variable "adminsport" {
  default = "8443"
}
variable "lb_ingress_ip" {
  
}
variable "consul_version" {
  
}
