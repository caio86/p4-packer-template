#cloud-config
autoinstall:
  version: 1

  locale: en_US.UTF-8
  keyboard:
    layout: us
  timezone: America/Recife

  identity:
    hostname: bmv2-template
    username: vagrant
    password: "$6$p4boxsalt$SWmtwRnRsp2gFcV.Q6XBzMxA8ztwXwGs7b4XgmsGnKv2WRH50PEhPgH9s3aSEzU99NilhW.58NiBTzOCgarJ20"

  ssh:
    install-server: true
    allow-pw: false
    authorized-keys:
      - ${ssh_public_key}

  packages:
    - ca-certificates
    - cloud-init
    - openssh-server
    - qemu-guest-agent
    - curl
    - iproute2
    - tcpdump
    - ethtool

  storage:
    layout:
      name: direct

  updates: all

  user-data:
    ssh_pwauth: false

    users:
      - name: vagrant
        groups: [sudo]
        lock-passwd: false
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
