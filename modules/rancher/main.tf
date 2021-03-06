terraform {
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
      version = "1.22.2"
      configuration_aliases = [ rancher2.admin, rancher2.bootstrap]
    }
  }
}

resource "helm_release" "rancher" {
  name       = "rancher"
  repository = "https://releases.rancher.com/server-charts/latest" 
  chart      = "rancher"
  version    = var.rancher_version
  namespace  = "cattle-system"

  set {
    name  = "hostname"
    value = var.rancher_hostname
  }

  set {
    name = "bootstrapPassword"
    value = var.rancher_password
  }

  depends_on = [helm_release.cert-manager]
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io" 
  chart      = "cert-manager"
  version    = var.certmanager_version
  namespace  = "cert-manager"

  depends_on = [null_resource.cert-manager-prereqs]
}

resource "null_resource" "cert-manager-prereqs" {

  provisioner "local-exec" {
    command = "kubectl create ns cattle-system --kubeconfig=kube_config_cluster.yml"
  }

  provisioner "local-exec" {
    command = "kubectl create ns cert-manager --kubeconfig=kube_config_cluster.yml"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.crds.yaml --kubeconfig=kube_config_cluster.yml"
  }


}

#Bootstrapping Rancher Cluster
resource "rancher2_bootstrap" "admin" {
  depends_on = [helm_release.rancher]
  provider = rancher2.bootstrap
  initial_password = var.rancher_password
  password = var.rancher_password
  telemetry = false
  token_update = false
}

output   token_key {
  value =   rancher2_bootstrap.admin.token
}

# Create a new rancher2 Cloud Credential
resource "rancher2_cloud_credential" "fremont" {
  depends_on = [rancher2_bootstrap.admin, helm_release.rancher ]
  provider = rancher2.admin
  name = "fremont"
  description = "fremont credentials"
  vsphere_credential_config {
    username = var.vsphere_user
    password = var.vsphere_password
    vcenter = var.vsphere_server
    vcenter_port = "443"
  }
}

output "cloud_credential" {
  value = rancher2_cloud_credential.fremont.id
}
