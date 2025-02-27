module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  image = {
    version = "v1.9.4"
    update_version = "v1.9.4" # renovate: github-releases=siderolabs/talos
    schematic = file("${path.module}/talos/image/schematic.yaml")
    # Point this to a new schematic file to update the schematic
    update_schematic = file("${path.module}/talos/image/schematic.yaml")
  }

  cilium = {
    values  = file("${path.module}/../../k8s/infra/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  cluster = {
    name = "talos"
    # This points to the vip as below(if nodes on layer 2) or one of the nodes (if nodes not on layer 2)
    # Note: Nodes are not on layer 2 if there is a router between them (even a mesh router)
    #       Not sure how it works if connected to the same router via ethernet (does it act as a switch then???)
    endpoint = "192.168.71.50"
    # Omit this if devices are not connected on layer 2
    vip             = "192.168.71.50"
    gateway         = "192.168.64.1"
    subnet_mask     = "18"
    talos_version   = "v1.9.4"
    proxmox_cluster = "HomeLab"
  }

  nodes = {
    "talos-ctrl-01" = {
      host_node     = "pve01"
      machine_type  = "controlplane"
      ip            = "192.168.71.51"
      mac_address   = "BC:24:11:DE:49:29"
      vm_id         = 201
      cpu           = 2
      ram_dedicated = 4096
      #igpu          = true
      #update = true
    }
    "talos-ctrl-02" = {
      host_node     = "pve02"
      machine_type  = "controlplane"
      ip            = "192.168.71.52"
      mac_address   = "BC:24:11:83:29:D1"
      vm_id         = 202
      cpu           = 2
      ram_dedicated = 4096
      #igpu          = true
      update = true
    }
    "talos-ctrl-03" = {
      host_node     = "pve03"
      machine_type  = "controlplane"
      ip            = "192.168.71.53"
      mac_address   = "BC:24:11:C7:12:F2"
      vm_id         = 203
      cpu           = 2
      ram_dedicated = 4096
      #igpu          = true
      #update        = true
    }
  }
}

module "sealed_secrets" {
  depends_on = [module.talos]
  source     = "./bootstrap/sealed-secrets"

  providers = {
    kubernetes = kubernetes
  }

  // openssl req -x509 -days 365 -nodes -newkey rsa:4096 -keyout sealed-secrets.key -out sealed-secrets.crt -subj "/CN=sealed-secret/O=sealed-secret"
  cert = {
    cert = file("${path.module}/bootstrap/sealed-secrets/certificates/sealed-secrets.crt")
    key  = file("${path.module}/bootstrap/sealed-secrets/certificates/sealed-secrets.key")
  }
}

module "proxmox_csi_plugin" {
  depends_on = [module.talos]
  source     = "./bootstrap/proxmox-csi-plugin"

  providers = {
    proxmox    = proxmox
    kubernetes = kubernetes
  }

  proxmox = var.proxmox
}

module "volumes" {
  depends_on = [module.proxmox_csi_plugin]
  source     = "./bootstrap/volumes"

  providers = {
    restapi    = restapi
    kubernetes = kubernetes
  }
  proxmox_api = var.proxmox
  volumes = {
  }
}
