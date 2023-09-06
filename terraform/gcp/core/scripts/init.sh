#! /bin/bash -e
apt update
apt install software-properties-common

curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt update && apt-get install boundary-enterprise -y

mkdir -p /etc/boundary/worker

# create the boundary config
cat <<EOF > /etc/boundary/config.hcl
hcp_boundary_cluster_id = "${cluster_id}"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  tags {
    type   = ["prod"]
    region = ["eu-west-1"]
  }

  controller_generated_activation_token = "${worker_token}"
  auth_storage_path = "/etc/boundary/worker"
}
EOF

# create the system d unit
cat <<EOF > /etc/systemd/system/boundary_worker.service
[Unit]
Description=Boundary Worker

[Service]
ExecStart=/usr/bin/boundary server -config="/etc/boundary/config.hcl"

[Install]
WantedBy=multi-user.target
EOF

systemctl enable /etc/systemd/system/boundary_worker.service
systemctl daemon-reload
systemctl start boundary_worker
