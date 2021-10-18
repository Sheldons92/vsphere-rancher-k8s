variable rancher_hostname {
  type        = string
  description = "Name for the Rancher host"
}

variable elastic_password {
  type        = string
  description = "Location of template for downstream RKE Clusters in format /DC/Folder/Name"
}