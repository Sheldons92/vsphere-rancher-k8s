# Rancher and RKE on vSphere With 2 Downstream Clusters Terraform Script


This repo creates the following:

* 1x NGINX Loadbalancer
* 3x RKE Nodes leveraging Embedded HA, forming a K8s Cluster
* Installation of `Cert-Manager` and `Rancher` 
* 2x Downstream RKE Clusters with Monitoring Enabled (Prod & Utility)
* Installs Longhorn in to Utility cluster for PVs
* Configures NGINX External LB for Utility Cluster Ingress
* Installs ECK operator in to the Utility cluster
* Installs ElasticSearch & Kibana

# Prerequisites

* Prior to running this script, two DNS records need to be created to point at the 2x Loadbalancer IP addresses, defined in the variables `lb_address` & `utility_lb_Address`.

* The VM template used must have the `Cloud-Init Datasource for VMware GuestInfo` project installed, which facilitates pulling meta, user, and vendor data from VMware vSphere's GuestInfo interface. This can be achieved with:

```
curl -sSL https://raw.githubusercontent.com/vmware/cloud-init-vmware-guestinfo/master/install.sh | sh -
```

Or use the following Packer Template:

https://github.com/David-VTUK/Rancher-Packer/tree/master/vSphere/ubuntu_2004_cloud_init_guestinfo

# Instructions

* Copy `variables.tfvars.example` as `variables.tfvars`
* Populate as you see fit
* Apply with `terraform apply --var-file variables.tfvars`
* Once comple, Terraform will output the URL for Rancher, IE:

```
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

rancher_url = https://rancher.nip.io
```
This repository is based off David Holders Rancher vSphere Repo (https://github.com/David-VTUK/Rancher-RKE-vSphere)

# TODO
* Remove hardcoded values where necessary
* Extract ES Creds for Rancher Logging
* SSL/TLS On Ingress & Elastic
* Update Architecture Diagram
* Upgrade Monitoring to 0.2.X
* New architecture diagram