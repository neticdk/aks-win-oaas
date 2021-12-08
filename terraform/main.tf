resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-${var.cluster_id}"
  location = "West Europe"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_id
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.cluster_id

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  windows_profile {
    admin_username = "netic"
    admin_password = var.admin_pw
  }

  network_profile {
    network_plugin = "azure"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "aks_pool" {
  name                  = "extra"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_DS2_v2"
  os_type               = "Windows"
  node_count            = 3
}

data "azurerm_virtual_machine_scale_set" "aks_pool" {
  name                = "aks${azurerm_kubernetes_cluster_node_pool.aks_pool.name}"
  resource_group_name = "MC_${azurerm_resource_group.rg.name}_${azurerm_kubernetes_cluster.aks.name}_${azurerm_resource_group.rg.location}"
}

## Install extension to run windows exporter
# Corresponding az commandline
# az vmss extension set \
#  --resource-group myResourceGroup \
#  --vmss-name myvmss \
#  --name DSC \
#  --publisher Microsoft.Powershell \
#  --version 2.80 \
#  --protected-settings '{}' \
#  --settings '{"wmfVersion":"latest","configuration":{"url":"https://github.com/neticdk/aks-win-oaas/releases/download/v0.0.10/pwe-vmss-extension.zip","script":"ConfigureWindowsExporter.ps1","function":"WindowsExporter"},"privacy":{"dataEnabled":"Disable"}}'

resource "azurerm_virtual_machine_scale_set_extension" "windows_exporter" {
  name                         = "windows-exporter-dsc"
  virtual_machine_scale_set_id = data.azurerm_virtual_machine_scale_set.aks_pool.id
  publisher                    = "Microsoft.Powershell"
  type                         = "DSC"
  type_handler_version         = "2.80"
  auto_upgrade_minor_version   = true
  settings = jsonencode({
    wmfVersion = "latest"
    configuration = {
      url      = "https://github.com/neticdk/aks-win-oaas/releases/download/v0.0.10/pwe-vmss-extension.zip"
      script   = "ConfigureWindowsExporter.ps1"
      function = "WindowsExporter"
    }
    privacy = {
      dataEnabled = "Disable"
    }
  })
}

resource "local_file" "kubeconfig" {
  filename          = "kube_config.yaml"
  sensitive_content = azurerm_kubernetes_cluster.aks.kube_config_raw
  file_permission   = "0600"
}

## Install Observability Helm chart
# Corresponsing Helm cli
# helm repo add netic-oaas http://neticdk.github.io/k8s-oaas-observability
# helm --kubeconfig ./kube_config.yaml install oaas-observability netic-oaas/oaas-observability -f oaas.values.yaml
resource "helm_release" "observability" {
  name       = "oaas-observability"
  repository = "https://neticdk.github.io/k8s-oaas-observability"
  chart      = "oaas-observability"
  version    = "2.0.18"

  create_namespace = true
  namespace        = "netic-observability-system"

  values = [
    "${file("oaas.values.yaml")}"
  ]
}
