#!/bin/bash
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

#CTS Install
sudo apt-get install unzip
sudo apt-get install curl gnupg lsb-release
sudo curl --fail --silent --show-error --location https://apt.releases.hashicorp.com/gpg | \
      gpg --dearmor | \
      sudo dd of=/usr/share/keyrings/hashicorp-archive-keyring.gpg

sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
 sudo tee -a /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update

sudo apt-get install consul-terraform-sync

#Terraform Install 

sudo apt update -y
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update -y
sudo apt install vault terraform unzip -y

#Download Consul
curl --silent --remote-name https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip

#Install Consul
unzip consul_${consul_version}_linux_amd64.zip
sudo chown root:root consul
sudo mv consul /usr/local/bin/
consul -autocomplete-install
complete -C /usr/local/bin/consul consul

#Create Consul User
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul


#Install consul terraform sync user and groups
sudo useradd --system --home /etc/consul-tf-sync.d --shell /bin/false consul-nia
sudo mkdir -p /opt/consul-tf-sync.d && sudo mkdir -p /etc/consul-tf-sync.d

sudo chown --recursive consul-nia:consul-nia /opt/consul-tf-sync.d && \
sudo chmod -R 0750 /opt/consul-tf-sync.d && \
sudo chown --recursive consul-nia:consul-nia /etc/consul-tf-sync.d && \
sudo chmod -R 0750 /etc/consul-tf-sync.d


# #Create Systemd Config for Consul Terraform Sync
sudo cat << EOF > /etc/systemd/system/consul-tf-sync.service
[Unit]
Description="HashiCorp Consul Terraform Sync - A Network Infra Automation solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
[Service]
User=root
Group=root
ExecStart=/usr/bin/consul-terraform-sync start -config-file=/etc/consul-tf-sync.d/consul-tf-sync-secure.hcl
KillMode=process
Restart=always
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

#Create Systemd Config
sudo cat << EOF > /etc/systemd/system/consul.service
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/server.hcl
[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=always
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

#Create config dir
sudo mkdir --parents /etc/consul.d
sudo touch /etc/consul.d/server.hcl
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/server.hcl

#Create CA certificate files
sudo touch /etc/consul.d/consul-agent-ca.pem
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul-agent-ca.pem
sudo touch /etc/consul.d/consul-agent-ca-key.pem
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul-agent-ca-key.pem

#Populate CA certificate files
cat << EOF > /etc/consul.d/consul-agent-ca.pem
${consul_ca_cert}
EOF
cat << EOF > /etc/consul.d/consul-agent-ca-key.pem
${consul_ca_key}
EOF

sudo chown --recursive consul:consul /etc/consul.d


#Create Consul config file
cat << EOF > /etc/consul.d/server.hcl
datacenter = "${consul_datacenter}"
data_dir = "/opt/consul"
client_addr = "0.0.0.0"
bind_addr = "0.0.0.0"
retry_join = ["${consul_server_ip}"]
acl { 
	enabled = true
	default_policy = "deny"
	enable_token_persistence = true
	tokens {
		agent = "${consul_acl_token}"
	}
}
connect {
    enabled = true
}
verify_incoming = false
verify_outgoing = false
verify_server_hostname = false
encrypt = "${consul_gossip_key}"
ca_file = "/etc/consul.d/consul-agent-ca.pem"
ports {
  http = 8500
  https = 8501
}
EOF



cat << EOF > /etc/consul-tf-sync.d/consul-tf-sync-secure.hcl
# Global Config Options
working_dir = "/opt/consul-tf-sync.d/"
log_level = "info"
buffer_period {
  min = "5s"
  max = "20s"
}
id = "consul-terraform-sync"
consul {
    address = "localhost:8500"
    token = "
    service_registration {
      enabled = true
      service_name = "consul-terraform-sync"
      default_check {
        enabled = true
        address = "http://localhost:8558"
      }
    }
}


driver "terraform" {
  log = true
  path = "/opt/consul-tf-sync.d/"
  required_providers {
    fortimanager = {
      source = "fortinetdev/fortimanager"
    }
  }
}


terraform_provider "fortimanager" {
    hostname     = "184.72.107.138:8443"
    insecure     = "true"
    username     = "admin"
    password     = "${fortigate_password}"
}

## Consul Terraform Sync Task Definitions
task {
  name = "fortinet"
  description = "Automate population of dynamic address group"
  module = "github.com/fortinetdev/terraform-fortimanager-cts-agpu"
  providers = ["fortimanager"]
  condition "services" {
    names = ["web", "api", "db", "logging"]
  }  
}
EOF

cat << EOF > /etc/consul-tf-sync.d/fortimanager.tfvars
addrgrp_name_map = {
  "<Address group name 1>" : <List of services>, # e.g. "cts-finance" : ["finance_workstations"],
  "<Address group name 2>" : <List of services> # e.g. "cts-windows" : ["windows10", "windows11"]
}
EOF

EOF




#Enable the service
sudo systemctl enable consul
sudo service consul start
sudo service consul status

sudo systemctl enable consul-tf-sync
sudo service consul-tf-sync start

sudo service consul-tf-sync status