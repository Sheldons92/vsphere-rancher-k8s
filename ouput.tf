output "rancher_url" {
  value = "https://${var.rancher_hostname}"
}

output "rke_nodes" {
  value = "${module.nodes.instance_ip_addr}"
}

//output "cloud_credential_id" {
//  value = rancher2_cloud_credential.fremont.id
//}