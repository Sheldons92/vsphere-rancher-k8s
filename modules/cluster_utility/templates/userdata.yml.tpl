#cloud-config
users:
  - name: ${vm_ssh_user}
    ssh_authorized_keys:
      - ${vm_ssh_key}
    sudo: ALL=(ALL) NOPASSWD:ALL
runcmd:
  - sudo usermod -aG docker ${vm_ssh_user}