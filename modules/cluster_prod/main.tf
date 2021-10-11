terraform {
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
      version = "1.20.1"
      configuration_aliases = [ rancher2.admin ]
    }
  }

}

resource "rancher2_node_template" "prod_ms_template" {
provider = rancher2.admin
  name                = "prod-master-template"
  description         = "Node template for prod K8s cluster master & cp nodes"
  cloud_credential_id = var.cloud_credential
  vsphere_config {
    creation_type             = "template"
    clone_from                = var.template_location
    cpu_count                 = 2
    memory_size               = 4092
    disk_size                 = 32000
    datacenter                = var.vsphere_datacenter
    datastore                 = var.vm_datastore
    pool                      = var.vsphere_pool"
    folder                    = ""
  }
}

resource "rancher2_node_template" "prod_worker_template" {
  provider = rancher2.admin
  name                = "prod-master-template"
  description         = "Node template for prod K8s cluster master & cp nodes"
  cloud_credential_id = var.cloud_credential
  vsphere_config {
    creation_type             = "template"
    clone_from                = var.template_location
    cpu_count                 = 4
    memory_size               = 8192
    disk_size                 = 32000
    datacenter                = var.vsphere_datacenter
    datastore                 = var.vm_datastore
    pool                      = var.vsphere_pool
    folder                    = ""
  }
}

# Rancher cluster template
resource "rancher2_cluster_template" "prod_template" {
  name = "prod-cluster"
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

  depends_on = [rancher2_node_template.prod_ms_template]
}

    resource "rancher2_cluster" "prod_cluster" {
      provider = rancher2.admin
      name = "prod-cluster"
      description = "Terraform"
      cluster_template_id = rancher2_cluster_template.prod_template.id
      cluster_template_revision_id = rancher2_cluster_template.prod_template.default_revision_id
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
        rancher2_cluster_template.prod_template]
    }

# Rancher masterpool
resource "rancher2_node_pool" "nodepool_master" {
  provider = rancher2.admin
  cluster_id = rancher2_cluster.prod_cluster.id
  name = "masters"
  hostname_prefix = "dsheldon-prod-master-"
  node_template_id = rancher2_node_template.prod_ms_template.id
  quantity = "1"
  control_plane = true
  etcd = true
  worker = false

  depends_on = [rancher2_cluster_template.prod_template]
}

# Rancher node pool
resource "rancher2_node_pool" "nodepool_worker" {
  provider = rancher2.admin
  cluster_id = rancher2_cluster.prod_cluster.id
  name = "workers"
  hostname_prefix = "dsheldon-prod-worker-"
  node_template_id = rancher2_node_template.prod_worker_template.id
  quantity = "1"
  control_plane = false
  etcd = false
  worker = true

  depends_on = [rancher2_cluster_template.prod_template]
}

resource "local_file" "kube_cluster_yaml" {
  filename = "${path.root}/prod_kube_config_cluster.yml"
  content  = rancher2_cluster.prod_cluster.kube_config
}