variable cloud_credential {
  type        = string
  description = "vSphere cloud credentials"
}

variable token_key {
  type        = string
  description = "rancher admin token for api"
}

variable rancher_hostname {
  type        = string
  description = "hostname for rancher"
}

variable vsphere_user {
  type        = string
  description = "Username for the vCenter instance"
}

variable vsphere_password {
  type        = string
  description = "Password for the vCenter instance"
}

variable vsphere_datacenter {
  type        = string
  description = "Name of the vCenter Datacenter object"
}

variable vsphere_cluster {
  type        = string
  description = "Name of the vCenter Cluster object"
}

variable vsphere_network {
  type        = string
  description = "Name of the vDS/vSS Port Group to attach to the VM's"
}

variable vm_prefix {
  type        = string
  description = "Name prefix for VM's. A numerical value will be appended"
}

variable vm_count {
  type        = number
  description = "Number of RKE instances to create"
}

variable vm_datastore {
  type        = string
  description = "Name of the vCenter datastore object"
}

variable vsphere_server {
  type        = string
  description = "FQDN or IP address of vCenter instance"
}

variable template_location {
  type        = string
  description = "Location of template for downstream RKE Clusters in format /DC/Folder/Name"
}

variable vsphere_pool {
  type        = string
  description = "name of vsphere pool for kubernetes clusters"
}

variable vm_template {
  type        = string
  description = "Name of VM template to use"
}

variable resource_pool {
  type        = string
  description = "resource pool for VMs"
}

variable lb_dns {
  type        = string
  description = "DNS Server for the Loadbalancer VM"
}

variable vm_dns {
  type        = string
  description = "DNS Server for the Loadbalancer VM"
}

variable lb_cpucount {
  type        = number
  description = "Number of CPU's to assign to the Loadbalancer VM"
}

variable lb_memory {
  type        = number
  description = "Amount of RAM in MB to assign to the Loadbalancer VM"
}

variable vm_ssh_key {
  type        = string
  description = "SSH key to add to the cloud-init for user access"
}

variable vm_ssh_user {
  type        = string
  description = "Username for ssh access"
}

variable lb_netmask {
  type        = string
  description = "Subnet Mask length for VM's"
}

variable utility_lb_address {
  type        = string
  description = "IP address for the NGINX loadbalancer"
}

variable utility_lb_prefix {
  type        = string
  description = "Name prefix for the Loadbalancer"
}

variable vm_gateway {
  type        = string
  description = "Gateway address for VM"
}

variable certmanager_version {
  type        = string
  description = "Version of Certmanager to install"
}
