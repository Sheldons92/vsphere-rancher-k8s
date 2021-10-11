output "instance_ip_addr" {
  value = vsphere_virtual_machine.rke-nodes.*.default_ip_address
}
