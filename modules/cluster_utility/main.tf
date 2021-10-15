terraform {
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
      version = "1.20.1"
      configuration_aliases = [ rancher2.admin ]
    }
    helm = {
      configuration_aliases = [ helm.utility ]
  }
  }

}

resource "rancher2_node_template" "utility_ms_template" {
provider = rancher2.admin
  name                = "utility-master-template"
  description         = "Node template for utility K8s cluster master & cp nodes"
  cloud_credential_id = var.cloud_credential
  vsphere_config {
    creation_type             = "template"
    clone_from                = var.template_location
    cpu_count                 = 2
    memory_size               = 4092
    disk_size                 = 32000
    datacenter                = var.vsphere_datacenter
    datastore                 = var.vm_datastore
    pool                      = var.vsphere_pool
    folder                    = ""
  }
}

resource "rancher2_node_template" "utility_worker_template" {
  provider = rancher2.admin
  name                = "utility-master-template"
  description         = "Node template for utility K8s cluster master & cp nodes"
  cloud_credential_id = var.cloud_credential
  vsphere_config {
    creation_type             = "template"
    clone_from                = var.template_location
    cpu_count                 = 4
    memory_size               = 8192
    disk_size                 = 80000
    datacenter                = var.vsphere_datacenter
    datastore                 = var.vm_datastore
    pool                      = var.vsphere_pool
    folder                    = ""
  }
}

# Rancher cluster template
resource "rancher2_cluster_template" "utility_template" {
  name = "utility-cluster"
  provider = rancher2.admin
  template_revisions {
    name = "v1"
    default = true
    cluster_config {
      cluster_auth_endpoint {
        enabled = false
      }
      rke_config {
        kubernetes_version = "v1.20.11-rancher1-1"
        ignore_docker_version = false
        network {
          plugin = "flannel"
        }
        cloud_provider {
          vsphere_cloud_provider {
            global {
              insecure_flag = true
            }
            virtual_center {
              datacenters = var.vsphere_datacenter
              name        = var.vsphere_server
              user        = var.vsphere_user
              password    = var.vsphere_password
            }
            workspace {
              server            = var.vsphere_server
              datacenter        = var.vsphere_datacenter
              folder            = "/"
              default_datastore = var.vm_datastore
            }
          }
        }
      }
    }
  }

  depends_on = [rancher2_node_template.utility_ms_template]
}

    resource "rancher2_cluster" "utility_cluster" {
      provider = rancher2.admin
      name = "utility-cluster"
      description = "Terraform"
      cluster_template_id = rancher2_cluster_template.utility_template.id
      cluster_template_revision_id = rancher2_cluster_template.utility_template.default_revision_id
      enable_cluster_monitoring = true
      cluster_monitoring_input {
        answers = {
          "exporter-kubelets.https" = true
          "exporter-node.enabled" = true
          "exporter-node.ports.metrics.port" = 9796
          "exporter-node.resources.limits.cpu" = "200m"
          "exporter-node.resources.limits.memory" = "200Mi"
          "grafana.persistence.enabled" = false
          "grafana.persistence.size" = "10Gi"
          "grafana.persistence.storageClass" = "default"
          "operator.resources.limits.memory" = "500Mi"
          "prometheus.persistence.enabled" = "false"
          "prometheus.persistence.size" = "10Gi"
          "prometheus.persistence.storageClass" = "default"
          "prometheus.persistent.useReleaseName" = "true"
          "prometheus.resources.core.limits.cpu" = "1000m",
          "prometheus.resources.core.limits.memory" = "1500Mi"
          "prometheus.resources.core.requests.cpu" = "750m"
          "prometheus.resources.core.requests.memory" = "750Mi"
          "prometheus.retention" = "12h"
        }
        version = "0.1.5" #TODO Upgrade to 0.2.X
      }
      depends_on = [
        rancher2_cluster_template.utility_template]
    }


# Rancher masterpool
resource "rancher2_node_pool" "nodepool_master" {
  provider = rancher2.admin
  cluster_id = rancher2_cluster.utility_cluster.id
  name = "masters"
  hostname_prefix = "dsheldon-utility-master-" #TODO Variablise
  node_template_id = rancher2_node_template.utility_ms_template.id
  quantity = "1" #TODO Variablise
  control_plane = true
  etcd = true
  worker = false

  depends_on = [rancher2_cluster_template.utility_template]
}

# Rancher node pool
resource "rancher2_node_pool" "nodepool_worker" {
  provider = rancher2.admin
  cluster_id = rancher2_cluster.utility_cluster.id
  name = "workers"
  hostname_prefix = "dsheldon-utility-worker-" #TODO Variablise
  node_template_id = rancher2_node_template.utility_worker_template.id
  quantity = "3" #TODO Variablise
  control_plane = false
  etcd = false
  worker = true

  depends_on = [rancher2_cluster_template.utility_template]
}


//# Delay hack part 1
//resource "null_resource" "before" {
//  depends_on = [rancher2_cluster.utility_cluster,rancher2_node_pool.nodepool_master,rancher2_node_pool.nodepool_worker]
//}

//# Delay hack part 2
//resource "null_resource" "delay" {
//  depends_on = [rancher2_cluster.utility_cluster]
//  provisioner "local-exec" {
//    command = "sleep 780"
//  }
//}

resource "rancher2_cluster_sync" "utility_master" {
  provider = rancher2.admin
  cluster_id = rancher2_cluster.utility_cluster.id
  node_pool_ids = [
    rancher2_node_pool.nodepool_master.id
  ]
}

resource "rancher2_cluster_sync" "utility_worker" {
  provider = rancher2.admin
  cluster_id = rancher2_cluster.utility_cluster.id
  node_pool_ids = [
    rancher2_node_pool.nodepool_worker.id
  ]
}

resource "local_file" "kube_cluster_yaml" {
  filename = "${path.root}/utility_kube_config_cluster.yml"
  content  = rancher2_cluster.utility_cluster.kube_config
  file_permission = "0600"

}

resource "helm_release" "cert-manager" {
  provider = helm.utility
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.certmanager_version
  namespace  = "cert-manager"

  depends_on = [null_resource.cert-manager-prereqs]
}

resource "null_resource" "cert-manager-prereqs" {
  depends_on = [rancher2_cluster_sync.utility_worker]

  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.crds.yaml --kubeconfig=utility_kube_config_cluster.yml"
  }

  provisioner "local-exec" {
    command = "kubectl create ns cattle-system --kubeconfig=utility_kube_config_cluster.yml"
  }

  provisioner "local-exec" {
    command = "kubectl create ns cert-manager --kubeconfig=utility_kube_config_cluster.yml"
  }
}

resource "null_resource" "nginx_service" {
  depends_on = [rancher2_cluster_sync.utility_worker]

  provisioner "local-exec" {
    command = "kubectl apply -f /modules/cluster_utility/templates/nginx_svc.yml --kubeconfig=utility_kube_config_cluster.yml"
  }
}


#install Longhorn
resource "rancher2_app_v2" "longhorn" {
  depends_on = [rancher2_cluster_sync.utility_master, rancher2_cluster_sync.utility_worker]
  provider = rancher2.admin
  cluster_id = rancher2_cluster.utility_cluster.id
  name = "longhorn"
  namespace = "longhorn-system"
  repo_name = "rancher-charts"
  chart_name = "longhorn"
  chart_version = "1.0.201"
}

# Create a new Rancher2 Cluster Logging
resource "rancher2_cluster_logging" "ecklogging" {
  depends_on = [rancher2_cluster_sync.utility_master, rancher2_cluster_sync.utility_worker]
  provider = rancher2.admin
  name = "ecklogging"
  cluster_id = rancher2_cluster.utility_cluster.id
  kind = "elasticsearch"
  elasticsearch_config {
    endpoint = "http://ip:9200"
    auth_username = "elastic"
    auth_password = "test" #this wont work yet
    index_prefix = "utility"
    ssl_verify = false
  }
}

output "utility_worker_ips" {
  value = "${rancher2_cluster_sync.utility_worker.nodes[*].ip_address}"
}

#Creating LB for Cluster

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}


data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.vm_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.resource_pool
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}


resource "vsphere_virtual_machine" "utility-lb" {
  name             = var.utility_lb_prefix
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = var.lb_cpucount
  memory   = var.lb_memory
  guest_id = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "disk0"
    size  = 32
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  extra_config = {
    "guestinfo.metadata" = base64encode(templatefile("${path.module}/templates/metadata.yml.tpl", {
      node_ip       = "${var.utility_lb_address}/${var.lb_netmask}"
      node_gateway  = var.vm_gateway,
      node_dns      = var.vm_dns,
      node_hostname = var.utility_lb_prefix
    }))

    "guestinfo.metadata.encoding" = "base64"


    "guestinfo.userdata" = base64encode(templatefile("${path.module}/templates/userdata_lb.yml.tpl", {
      servers = rancher2_cluster_sync.utility_worker.nodes[*].ip_address,
      vm_ssh_user = var.vm_ssh_user,
      vm_ssh_key = var.vm_ssh_key
    }))
    "guestinfo.userdata.encoding" = "base64"


  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install nginx -y",
      "sudo cp /root/nginx.conf /etc/nginx/nginx.conf ", #Changed to CP for testing that this is working.
      "sudo service nginx restart"
    ]

    connection {
      agent = "true"
      type     = "ssh"
      host     = self.default_ip_address
      user     = var.vm_ssh_user
    }
  }
}

