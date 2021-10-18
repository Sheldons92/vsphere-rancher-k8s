terraform {
  required_providers {
    helm = {
      configuration_aliases = [ helm.utility ]
    }
  }
}

resource "helm_release" "elastic-operator" {
  provider = helm.utility
  name       = "elastic-operator"
  repository = "https://helm.elastic.co"
  chart  = "eck-operator"

  set {
    name = "installCRDS"
    value = "true"
  }
  set {
    name = "create_namespace"
    value = "true"
  }
  set {
    name = "namespace"
    value = "elastic"
  }
}

resource "null_resource" "elastic_secret" {
depends_on = [helm_release.elastic-operator]
provisioner "local-exec" {
command = "kubectl create secret generic elasticsearch-es-elastic-user --from-literal=elastic=${var.elastic_password} --kubeconfig=utility_kube_config_cluster.yml"
}

}
resource "null_resource" "elasticsearch" {
  depends_on = [helm_release.elastic-operator]
  provisioner "local-exec" {
    command = "kubectl apply -f modules/ECK/yaml/elasticsearch.yaml --kubeconfig=utility_kube_config_cluster.yml"
  }
}

resource "null_resource" "elasticsearch_ingress" {
  depends_on = [helm_release.elastic-operator]
  provisioner "local-exec" {
    command = "kubectl apply -f modules/ECK/yaml/ingress.yml --kubeconfig=utility_kube_config_cluster.yml"
  }
}

resource "null_resource" "kibana" {
  depends_on = [helm_release.elastic-operator]
  provisioner "local-exec" {
    command = "kubectl apply -f modules/ECK/yaml/kibana.yaml --kubeconfig=utility_kube_config_cluster.yml"
  }
}