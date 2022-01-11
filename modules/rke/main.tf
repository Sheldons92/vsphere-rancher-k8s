terraform {
  required_providers {
    rke = {
      source  = "rancher/rke"
      version = "1.3.0"
    }
  }
  required_version = ">= 0.13"
}

resource rke_cluster "cluster" {
  ssh_agent_auth     = true
  cluster_name = "cluster"
  # kubernetes_version = "<K8s_VERSION>"
  dynamic "nodes" {

    for_each = var.vm_address

    content {
      user = "packerbuilt"
      address = nodes.value
      internal_address = nodes.value
      role    = ["controlplane", "worker", "etcd"]
    }

  }

}

resource "local_file" "kube_cluster_yaml" {
  filename = "${path.root}/kube_config_cluster.yml"
  content  = rke_cluster.cluster.kube_config_yaml
}