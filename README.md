NOTE on mac m1 users
if you get this error, you can use docker to deploy the configuration

│ Provider registry.terraform.io/hashicorp/template v2.2.0 does not have a package available for your current platform, darwin_arm64.
First, make sure that you have docker installed on your machine.. than you can execute the following command.

docker-compose -f docker-compose.yaml run --rm terraform init

docker-compose -f docker-compose.yaml run --rm terraform plan

docker-compose -f docker-compose.yaml run --rm terraform apply