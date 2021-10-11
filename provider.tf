provider "rancher2" {
  alias = "bootstrap"
  api_url  = "https://${var.rancher_hostname}"
  bootstrap = true
  insecure = true
}

provider "rancher2" {
  alias = "admin"
  api_url = "https://${var.rancher_hostname}"
  token_key = module.rancher.token_key
  insecure = true
}

provider "helm" {
  kubernetes {
    config_path = "./kube_config_cluster.yml"
  }
}

provider "helm" {
  alias = "utility"
  kubernetes {
    config_path = "./utility_kube_config_cluster.yml"
  }
}

provider "helm" {
  alias = "prod"
  kubernetes {
    config_path = "./prod_kube_config_cluster.yml"
  }
}

provider "kubernetes" {
  config_path = "./kube_config_cluster.yml"
}