#!/bin/bash

#Utils
sudo apt-get install unzip

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


cat << EOF > /etc/consul.d/fakeservice.hcl
service {
  id      = "web"
  name    = "web"
  tags    = ["web"]
  port    = 9090
  token = "${consul_acl_token}"
  check {
    id       = "web"
    name     = "TCP on port 9090"
    tcp      = "localhost:9090"
    interval = "10s"
    timeout  = "1s"
  }
}
EOF



#Enable the service
sudo systemctl enable consul
sudo service consul start
sudo service consul status


#Install Dockers
sudo snap install docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


sleep 10
cat << EOF > docker-compose.yml
version: "3.7"
services:

  web:
    image: nicholasjackson/fake-service:v0.7.8
    environment:
      LISTEN_ADDR: 0.0.0.0:9090
      UPSTREAM_URIS: "http://localhost:9094"
      MESSAGE: "Hello World"
      NAME: "web"
      SERVER_TYPE: "http"
    ports:
    - "9090:9090"


EOF
sudo docker-compose up -d
