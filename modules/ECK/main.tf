terraform {
  required_providers {
    helm = {
      configuration_aliases = [ helm.utility ]
    }
  }
}

#this doesn't work...
//resource "null_resource" "wait_for_cluster" {
//  provisioner "local-exec" {
//    command =
//    <<EOF
//        while true; do curl -kv -u -u ${var.access_key}:${var.secret_access_key} https://${var.rancher_hostname}/v3/clusters\?name\=utility-cluster | jq -r '.data[0] | .state'; if [[ $1 != "active" ]]; then echo "Utility Cluster is not Active yet"; sleep 5; continue; fi; break; done; echo "Utility Cluster is ready";
//    EOF
//  }
//}

resource "helm_release" "elastic-operator" {
//  depends_on = [null_resource.wait_for_cluster]
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

resource "null_resource" "elasticsearch" {
  depends_on = [helm_release.elastic-operator]
  provisioner "local-exec" {
    command = "kubectl apply -f modules/ECK/yaml/elasticsearch.yaml --kubeconfig=utility_kube_config_cluster.yml"
  }
}

resource "null_resource" "kibana" {
  depends_on = [helm_release.elastic-operator]
  provisioner "local-exec" {
    command = "kubectl apply -f modules/ECK/yaml/kibana.yaml --kubeconfig=utility_kube_config_cluster.yml"
  }
}