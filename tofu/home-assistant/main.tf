terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.70.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_node.endpoint
  insecure = var.proxmox_node.insecure

  api_token = var.proxmox_node.api_token
  ssh {
    agent    = true
    username = var.proxmox_node.username
  }
}