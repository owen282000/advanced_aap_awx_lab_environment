terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = "**************************************************"
}

locals {
  total_machines = var.num_participants * var.machines_per_participant

  ssh_key_path   = ".ssh/id_rsa.pub"

  managed_node_urns = [
    for i in range(local.total_machines - var.num_participants) :
    digitalocean_droplet.managed_node[i].urn
  ]

  awx_server_urns = [
    for i in range(var.num_participants) :
    digitalocean_droplet.awx_server[i].urn
  ]

  awx_ips_str = join(",", digitalocean_droplet.awx_server.*.ipv4_address)
  managed_node_ips_str = join(",", digitalocean_droplet.managed_node.*.ipv4_address)
}

resource "digitalocean_ssh_key" "advanced_aap_lab" {
  name       = "advanced_aap_lab"
  public_key = file(local.ssh_key_path)
}

resource "digitalocean_droplet" "awx_server" {
  count = var.num_participants
  name  = "awx-${count.index + 1}"
  region = "ams3"
  size   = var.awx_size
  image  = "centos-stream-9-x64"
  ssh_keys = [digitalocean_ssh_key.advanced_aap_lab.fingerprint]
  tags = ["awx"]

  provisioner "remote-exec" {
    inline = [
      "echo 'Starting provisioning' > /tmp/terraform_provisioner.log",
      "repo_file='/etc/yum.repos.d/centos.repo'",
      "if [ -f $repo_file ]; then",
      "  sed -i 's|^#baseurl=http://mirror.centos.org/centos/\\\\$releasever|baseurl=http://mirror.centos.org/centos/\\\\$releasever|g' $repo_file",
      "  sed -i 's|^mirrorlist=|#mirrorlist=|g' $repo_file",
      "else",
      "  echo 'Repo file not found: $repo_file' >> /tmp/terraform_provisioner.log",
      "fi",
      "yum clean all >> /tmp/terraform_provisioner.log 2>&1",
      "yum makecache >> /tmp/terraform_provisioner.log 2>&1",
      "yum update -y >> /tmp/terraform_provisioner.log 2>&1 || (echo 'Retrying yum update' >> /tmp/terraform_provisioner.log && yum clean packages >> /tmp/terraform_provisioner.log 2>&1 && yum update -y >> /tmp/terraform_provisioner.log 2>&1)",
      "yum install -y python3 python3-pip >> /tmp/terraform_provisioner.log 2>&1 || (echo 'Retrying yum install' >> /tmp/terraform_provisioner.log && yum clean packages >> /tmp/terraform_provisioner.log 2>&1 && yum install -y python3 python3-pip >> /tmp/terraform_provisioner.log 2>&1)",
      "echo 'Provisioning complete' >> /tmp/terraform_provisioner.log"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(".ssh/id_rsa")
      host        = self.ipv4_address
    }
  }
}

resource "digitalocean_droplet" "managed_node" {
  count = local.total_machines - var.num_participants
  name  = "node-${count.index + 1}"
  region = "ams3"
  size   = var.managed_node_size
  image  = "centos-stream-9-x64"
  ssh_keys = [digitalocean_ssh_key.advanced_aap_lab.fingerprint]
  tags = ["managed"]

  provisioner "remote-exec" {
    inline = [
      "echo 'Starting provisioning' > /tmp/terraform_provisioner.log",
      "repo_file='/etc/yum.repos.d/centos.repo'",
      "if [ -f $repo_file ]; then",
      "  sed -i 's|^#baseurl=http://mirror.centos.org/centos/\\\\$releasever|baseurl=http://mirror.centos.org/centos/\\\\$releasever|g' $repo_file",
      "  sed -i 's|^mirrorlist=|#mirrorlist=|g' $repo_file",
      "else",
      "  echo 'Repo file not found: $repo_file' >> /tmp/terraform_provisioner.log",
      "fi",
      "yum clean all >> /tmp/terraform_provisioner.log 2>&1",
      "yum makecache >> /tmp/terraform_provisioner.log 2>&1",
      "yum update -y >> /tmp/terraform_provisioner.log 2>&1 || (echo 'Retrying yum update' >> /tmp/terraform_provisioner.log && yum clean packages >> /tmp/terraform_provisioner.log 2>&1 && yum update -y >> /tmp/terraform_provisioner.log 2>&1)",
      "yum install -y python3 python3-pip >> /tmp/terraform_provisioner.log 2>&1 || (echo 'Retrying yum install' >> /tmp/terraform_provisioner.log && yum clean packages >> /tmp/terraform_provisioner.log 2>&1 && yum install -y python3 python3-pip >> /tmp/terraform_provisioner.log 2>&1)",
      "echo 'Provisioning complete' >> /tmp/terraform_provisioner.log"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(".ssh/id_rsa")
      host        = self.ipv4_address
    }
  }
}

resource "null_resource" "install_ansible_collections" {
  provisioner "local-exec" {
    command = "ansible-galaxy collection install -r setup/requirements.yml"
  }
}

resource "null_resource" "setup_ansible" {
  depends_on = [
    digitalocean_droplet.awx_server,
    digitalocean_droplet.managed_node,
    null_resource.install_ansible_collections
  ]

  provisioner "local-exec" {
    command = <<EOT
      bash scripts/setup_ansible.sh ${var.num_participants} "${local.awx_ips_str}" "${local.managed_node_ips_str}"
    EOT
  }
}

resource "null_resource" "fetch_awx_details" {
  count = var.num_participants
  depends_on = [null_resource.setup_ansible]
  
  provisioner "local-exec" {
    command = <<EOT
      ssh -o StrictHostKeyChecking=no -i .ssh/id_rsa root@${digitalocean_droplet.awx_server[count.index].ipv4_address} 'cat /tmp/awx_access_details.txt' > /tmp/awx_access_details_${count.index}.txt
    EOT
  }
}

resource "null_resource" "generate_awx_json" {
  depends_on = [null_resource.fetch_awx_details]

  provisioner "local-exec" {
    command = "bash scripts/extract_awx_details.sh ${var.num_participants}"
  }

  triggers = {
    awx_details = "${var.num_participants}"
  }
}

resource "local_file" "awx_details_json" {
  content  = file("awx_details.json")
  filename = "${path.module}/awx_details.json"
  depends_on = [null_resource.generate_awx_json]
  
  lifecycle {
    ignore_changes = [content]
  }
}

data "local_file" "awx_details" {
  filename = "${path.module}/awx_details.json"
  depends_on = [local_file.awx_details_json]
}

locals {
  awx_details = jsondecode(data.local_file.awx_details.content)
}

resource "digitalocean_project" "project" {
  name        = "advanced_awx_lab"
  description = "AWX Lab"
  purpose     = "Educational purposes"
  resources   = concat(local.managed_node_urns, local.awx_server_urns)
}

### TODO: nettere SSH-Key leveren
