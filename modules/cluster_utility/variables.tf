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

variable elastic_password {
  type        = string
  description = "name of vsphere pool for kubernetes clusters"
}