packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1.1"
    }
    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = "~> 1"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "ssh_public_key_file" {
  type        = string
  description = "SSH public key used only during the Packer build."
  default     = "~/.ssh/packer-build.pub"
}

variable "ssh_private_key_file" {
  type        = string
  description = "SSH private key used only during the Packer build."
  default     = "~/.ssh/packer-build"
}

variable "disk_size" {
  type        = string
  description = "Size of the resulting VM disk."
  default     = "12G"
}

locals {
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_file)))
}

source "virtualbox-iso" "ubuntu-p4" {
  vm_name       = "ubuntu-24.04-p4"
  guest_os_type = "Ubuntu_64"
  disk_size     = 41000
  cpus          = 2
  memory        = 4096

  ssh_username           = "vagrant"
  ssh_private_key_file   = pathexpand(var.ssh_private_key_file)
  ssh_timeout            = "30m"
  ssh_handshake_attempts = 100

  iso_url      = "https://releases.ubuntu.com/24.04.5/ubuntu-24.04.5-live-server-amd64.iso"
  iso_checksum = "file:https://releases.ubuntu.com/24.04.5/SHA256SUMS"
  headless     = true

  boot_wait = "5s"
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]
  http_content = {
    "/user-data" = templatefile("${path.root}/http/user-data.pkrtpl.hcl", {
      ssh_public_key = local.ssh_public_key
    })
    "/meta-data" = file("${path.root}/http/meta-data")
  }

  shutdown_command = "echo vagrant | sudo -S shutdown -P now"
}


source "virtualbox-iso" "bmv2_switch" {
  iso_url      = "https://releases.ubuntu.com/24.04.5/ubuntu-24.04.5-live-server-amd64.iso"
  iso_checksum = "file:https://releases.ubuntu.com/24.04.5/SHA256SUMS"

  output_directory = "output/bmv2"
  guest_os_type    = "Ubuntu_64"
  vm_name          = "ubuntu-bmv2"
  disk_size        = 41000

  headless = true

  # Build-time resources.
  memory = 4096
  cpus   = 4

  hard_drive_interface = "sata"
  iso_interface        = "sata"

  # Ubuntu Server autoinstall files.
  http_content = {
    "/user-data" = templatefile("${path.root}/http/user-data.pkrtpl.hcl", {
      ssh_public_key = local.ssh_public_key
    })
    "/meta-data" = file("${path.root}/http/meta-data")
  }


  boot_wait = "5s"

  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]


  ssh_username           = "vagrant"
  ssh_private_key_file   = pathexpand(var.ssh_private_key_file)
  ssh_timeout            = "30m"
  ssh_handshake_attempts = 100

  shutdown_command = "sudo -n systemctl poweroff"
}

source "qemu" "bmv2_switch" {
  iso_url      = "https://releases.ubuntu.com/24.04.5/ubuntu-24.04.5-live-server-amd64.iso"
  iso_checksum = "file:https://releases.ubuntu.com/24.04.5/SHA256SUMS"

  output_directory = "output/bmv2-switch"
  vm_name          = "ubuntu-bmv2-switch.qcow2"
  format           = "qcow2"
  disk_size        = var.disk_size

  headless    = true
  accelerator = "kvm"

  # Build-time resources.
  memory = 4096
  cpus   = 4

  disk_interface = "virtio"
  net_device     = "virtio-net"

  # Ubuntu Server autoinstall files.
  http_content = {
    "/user-data" = templatefile("${path.root}/http/user-data.pkrtpl.hcl", {
      ssh_public_key = local.ssh_public_key
    })
    "/meta-data" = file("${path.root}/http/meta-data")
  }

  boot_wait = "3s"

  boot_command = [
    "<wait><esc><wait>",
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'<enter><wait>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]

  ssh_username           = "vagrant"
  ssh_private_key_file   = pathexpand(var.ssh_private_key_file)
  ssh_timeout            = "30m"
  ssh_handshake_attempts = 100

  shutdown_command = "sudo -n systemctl poweroff"
}

build {
  name = "bmv2-switch"
  sources = [
    "source.virtualbox-iso.ubuntu-p4"
    # "source.virtualbox-iso.bmv2_switch"
    # "source.qemu.bmv2_switch"
  ]

  provisioner "shell" {
    scripts = [
      "${path.root}/scripts/install-bmv2.sh",
      # "${path.root}/scripts/configure-bmv2.sh",
      "${path.root}/scripts/cleanup.sh",
    ]

    execute_command = "chmod +x {{ .Path }} && sudo -E {{ .Vars }} bash '{{ .Path }}'"

  }

  # provisioner "shell" {
  #   inline = [
  #     "sudo -n rm -f /etc/sudoers.d/90-cloud-init-users",
  #     "sudo -n userdel -r -f packer"
  #   ]
  # }

  post-processor "vagrant" {
    keep_input_artifact = false
    output              = "ubuntu-24.04-p4_{{.Provider}}.box"
  }
}
