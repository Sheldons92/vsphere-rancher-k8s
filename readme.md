# Rancher and RKE on vSphere With 2 Downstream Clusters Terraform Script


This repo creates the following:

* 2x NGINX Loadbalancer (1 For Rancher, 1 for Utility Cluster)
* 3x RKE Nodes leveraging Embedded HA, forming a K8s Cluster
* Installation of `Cert-Manager` and `Rancher` 
* 1x Downstream Rancher Provisioned Cluster with Monitoring Enabled (Utility)
* Installs Longhorn in to Utility cluster for PVs
* Installs ECK operator in to the Utility cluster - (To FIX)
* Installs ElasticSearch & Kibana - (To FIX)

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

rancher_url = https://rancher.IP.nip.io
```
This repository is based off David Holders Rancher vSphere Repo (https://github.com/David-VTUK/Rancher-RKE-vSphere)

# TODO
* Remove hardcoded values where necessary
* SSL/TLS On Ingress & Elastic
* Update Architecture Diagram
* Update to Rancher_App_v2 for logging (Or use beats)
* New architecture diagram
* Add dedicated longhorn disk to nodes.
* Make versions for Public Cloud (AWS/Azure/GCP)