terraform {
  required_version =">= 0.15"
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
      version = "1.22.2"
       }
    }
  }

module "nodes" {
  source             = "./modules/nodes"
  vsphere_server     = var.vsphere_server
  vsphere_user       = var.vsphere_user
  vsphere_password   = var.vsphere_password
  vsphere_datacenter = var.vsphere_datacenter
  vsphere_cluster    = var.vsphere_cluster
  vsphere_network    = var.vsphere_network

  vm_prefix     = var.vm_prefix
  vm_count      = var.vm_count
  vm_datastore  = var.vm_datastore
  vm_cpucount   = var.vm_cpucount
  vm_memory     = var.vm_memory
  vm_domainname = var.vm_domainname
  vm_network    = var.vm_network
  vm_netmask    = var.vm_netmask
  vm_gateway    = var.vm_gateway
  vm_dns        = var.vm_dns
  vm_template   = var.vm_template
  resource_pool = var.resource_pool



  lb_address    = var.lb_address
  lb_prefix     = var.lb_prefix
  lb_datastore  = var.lb_datastore
  lb_cpucount   = var.lb_cpucount
  lb_memory     = var.lb_memory
  lb_domainname = var.lb_domainname
  lb_netmask    = var.lb_netmask
  lb_gateway    = var.lb_gateway
  lb_dns        = var.lb_dns

  vm_ssh_key = var.vm_ssh_key
  vm_ssh_user = var.vm_ssh_user
}

module "rke" {
  source     = "./modules/rke"
  vm_count   = var.vm_count
  vm_address = "${module.nodes.instance_ip_addr}"

  depends_on = [module.nodes]

}

module "rancher" {
  source              = "./modules/rancher"
  providers = {
  rancher2.bootstrap = rancher2.bootstrap
  rancher2.admin = rancher2.admin
}

  certmanager_version = var.certmanager_version
  rancher_hostname    = var.rancher_hostname
  rancher_version     = var.rancher_version
  vsphere_cluster = var.vsphere_cluster
  vsphere_server = var.vsphere_server
  vsphere_user = var.vsphere_user
  vsphere_password = var.vsphere_password
  vsphere_datacenter = var.vsphere_datacenter
  rancher_password = var.rancher_password

  depends_on = [module.rke]
}


module "utility" {
  source              = "./modules/cluster_utility"
  providers = {
    rancher2.admin = rancher2.admin
    helm.utility = helm.utility
  }
  rancher_hostname = var.rancher_hostname
  token_key = module.rancher.token_key
  cloud_credential = module.rancher.cloud_credential
  vsphere_user = var.vsphere_user
  vsphere_password = var.vsphere_password
  vsphere_datacenter = var.vsphere_datacenter
  vsphere_cluster = var.vsphere_cluster
  vsphere_network = var.vsphere_network
  vm_count = "1" #TODO Figure out why I need this?
  vm_prefix = "null" #TODO Figure out why I need this?
  vsphere_server = var.vsphere_server
  vm_datastore = var.vm_datastore
  vsphere_pool = var.resource_pool
  template_location = var.template_location
  vm_template = var.vm_template
  resource_pool = var.resource_pool
  vm_dns = var.vm_dns
  lb_dns = var.lb_dns
  lb_cpucount = var.lb_cpucount
  lb_memory   = var.lb_memory
  vm_ssh_key = var.vm_ssh_key
  vm_ssh_user = var.vm_ssh_user
  utility_lb_prefix = var.utility_lb_prefix
  utility_lb_address = var.utility_lb_address
  lb_netmask = var.lb_netmask
  vm_gateway = var.vm_gateway
  certmanager_version = var.certmanager_version
  elastic_password = var.elastic_password
}



//module "prod" {
//  source = "./modules/cluster_prod"
//  providers = {
//    rancher2.admin = rancher2.admin
//  }
//  rancher_hostname = var.rancher_hostname
//  token_key = module.rancher.token_key
//  cloud_credential = module.rancher.cloud_credential
//  vsphere_user = var.vsphere_user
//  vsphere_password = var.vsphere_password
//  vsphere_datacenter = var.vsphere_datacenter
//  vsphere_cluster = var.vsphere_cluster
//  vsphere_network = var.vsphere_network
//  vm_count = "1"
//  #TODO Figure out why I need this?
//  vm_prefix = "null"
//  #TODO Figure out why I need this?
//  vsphere_server = var.vsphere_server
//  vm_datastore = var.vm_datastore
//  vsphere_pool = var.resource_pool
//  template_location = var.template_location
//}

# module "eck" {
#   source = "./modules/ECK"
#   elastic_password = var.elastic_password
#   providers = {
#     helm.utility = helm.utility
#   }
#     rancher_hostname = var.rancher_hostname
#     depends_on = [ module.utility ]
# }

resource "null_resource" "wait_for_rancher" {
  provisioner "local-exec" {
    command = <<EOF
      while true; do curl -kv https://"${var.rancher_hostname}" 2>&1 | grep -q "dynamiclistener-ca"; if [ $? != 0 ]; then echo "Rancher URL isn't ready yet"; sleep 5; continue; fi; break; done; echo "Rancher URL is Ready";
              EOF
  }

  depends_on = [module.rancher]
}

output "utility_worker_ips" {
  value = module.utility.utility_worker_ips
}