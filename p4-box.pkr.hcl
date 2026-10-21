packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "file:https://releases.ubuntu.com/22.04/SHA256SUMS"
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 4096
}

variable "disk_size" {
  type        = number
  default     = 40000 # MB, thin-provisioned
  description = "Virtual disk size in MB"
}

variable "headless" {
  type    = bool
  default = false
}

variable "box_version" {
  type    = string
  default = "0.1.0"
}

source "virtualbox-iso" "p4" {
  vm_name       = "p4-ubuntu2204"
  guest_os_type = "Ubuntu_64"

  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  cpus                 = var.cpus
  memory               = var.memory
  disk_size            = var.disk_size
  hard_drive_interface = "sata"
  iso_interface        = "sata"
  headless             = var.headless
  format               = "ova"

  guest_additions_mode = "upload"
  guest_additions_path = "/home/vagrant/VBoxGuestAdditions.iso"

  # Ubuntu autoinstall (subiquity) served from ./http through the NoCloud datasource
  http_directory = "http"
  boot_wait      = "5s"
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ",
    "<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  communicator           = "ssh"
  ssh_username           = "vagrant"
  ssh_password           = "vagrant"
  ssh_timeout            = "45m"
  ssh_handshake_attempts = 100

  shutdown_command = "echo 'vagrant' | sudo -S shutdown -P now"
}

build {
  sources = ["source.virtualbox-iso.p4"]

  # 1. Base packages + upgrade (reboots at the end)
  provisioner "shell" {
    execute_command   = "echo 'vagrant' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    script            = "scripts/00-base.sh"
    expect_disconnect = true
  }

  # 2. VirtualBox Guest Additions
  provisioner "shell" {
    execute_command = "echo 'vagrant' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "scripts/10-guest-additions.sh"
    pause_before    = "30s"
  }

  # 3. p4c + bmv2 (+ mininet, scapy, ...)
  provisioner "shell" {
    execute_command = "echo 'vagrant' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "scripts/20-p4.sh"
    timeout         = "60m"
  }

  # 4. Smoke test: compile a P4 program and start simple_switch (fails the build if broken)
  provisioner "shell" {
    execute_command = "echo 'vagrant' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "scripts/30-verify.sh"
  }

  # 5. Vagrant-specific setup + cleanup/shrink
  provisioner "shell" {
    execute_command = "echo 'vagrant' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    scripts = [
      "scripts/40-vagrant.sh",
      "scripts/99-cleanup.sh",
    ]
  }

  post-processor "vagrant" {
    output            = "builds/p4-ubuntu2204-${var.box_version}-{{ .Provider }}.box"
    compression_level = 9
  }
}
