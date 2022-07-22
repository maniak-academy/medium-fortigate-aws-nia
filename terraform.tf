terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.23.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.2"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}

  provider "aws" {
  region = var.region

}
