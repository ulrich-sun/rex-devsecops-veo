packer {
  required_version = ">= 1.9.2, < 2.0.0"
  required_plugins {
    amazon = {
      version = "1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

data "amazon-ami" "ubuntu_focal" {
    filters = {
      virtualization-type = "hvm"
      name = "ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"
      root-device-type = "ebs"
    }
    owners = ["099720109477"]
    most_recent = true
}

# Locals pour les valeurs calculées
locals {
  timestamp = formatdate("YYYYMMDD-hhmmss", timestamp())
  ami_name  = "${var.ami_prefix}-${local.timestamp}"
  merged_tags = merge(
    var.common_tags,
    {
      "Name"       = local.ami_name
      "OS"         = "Ubuntu"
      "OS_Version" = "20.04 LTS"
      "SourceAMI"  = data.amazon-ami.ubuntu_focal.id
    }
  )
}

# Configuration du builder Amazon EBS
source "amazon-ebs" "init_image" {
  region          = var.aws_region
  source_ami      = data.amazon-ami.ubuntu_focal.id
  ami_name        = local.ami_name
  ami_description = var.ami_description
  instance_type   = var.instance_type
  ssh_username    = var.ssh_username
  ssh_timeout     = var.ssh_timeout

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = var.root_volume_size
    volume_type           = "gp2"
    delete_on_termination = true
    encrypted             = true
  }

  tags          = local.merged_tags
  snapshot_tags = local.merged_tags
}

# Définition du build
build {
  name    = "init_image_build"
  sources = ["source.amazon-ebs.init_image"]
  
   provisioner "file" {
    source      = "./defaults.cfg"
    destination = "/tmp/defaults.cfg"
  }
  provisioner "file" {
    source      = "../scripts/motd"
    destination = "/tmp/motd"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/defaults.cfg /etc/cloud/cloud.cfg.d/defaults.cfg",
      "sudo mv /tmp/motd /etc/motd"
    ]
  }

  provisioner "shell" {
    scripts = ["../scripts/init.sh"]
    execute_command = "sudo -E -S sh '{{ .Path }}'"
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "PACKER_BUILD=1"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
    custom_data = {
      build_time = timestamp()
    }
  }
}