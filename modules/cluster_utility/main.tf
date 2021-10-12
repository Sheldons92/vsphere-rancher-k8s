terraform {
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
      version = "1.20.1"
      configuration_aliases = [ rancher2.admin ]
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

#install Longhorn
resource "rancher2_app_v2" "longhorn" {
  provider = rancher2.admin
  cluster_id = rancher2_cluster.utility_cluster.id
  name = "rancher-longhorn"
  namespace = "longhorn-system"
  repo_name = "rancher-charts"
  chart_name = "longhorn"
  chart_version = "1.0.201"
}

# Create a new Rancher2 Cluster Logging
resource "rancher2_cluster_logging" "ecklogging" {
  provider = rancher2.admin
  name = "ecklogging"
  cluster_id = rancher2_cluster.utility_cluster.id
  kind = "elasticsearch"
  elasticsearch_config {
    endpoint = "http://elasticsearch-es-default:9200"
    auth_username = "elastic"
    auth_password = var.elastic_password #this wont work yet
    index_prefix = "utility"
    ssl_verify = false
  }
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

resource "local_file" "kube_cluster_yaml" {
  filename = "${path.root}/utility_kube_config_cluster.yml"
  content  = rancher2_cluster.utility_cluster.kube_config
}