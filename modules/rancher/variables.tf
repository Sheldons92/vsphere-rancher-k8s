variable certmanager_version {
  type        = string
  description = "Version of Certmanager to install"
}

variable rancher_hostname {
  type        = string
  description = "Name for the Rancher host"
}

variable rancher_version {
  type        = string
  description = "Version of Rancher to install"
}

variable vsphere_server {
  type        = string
  description = "FQDN or IP address of vCenter instance"
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

//variable api_url {
//  type        = string
//  description = "api url of rancher"
//}

//variable token_key {
//  type = string
//}