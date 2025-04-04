# This random string is used as part of resource naming. It can be changed or ignored as necessary.
resource "random_string" "name-modifier" {
    length = 5
    special = false
    upper = false
}

locals {


  kv_item_expiration_date = var.set_kv_expiration_dates ? formatdate("YYYY-MM-DD'T'00:00:00'Z'", timeadd(timestamp(), "${(var.azure_keyvault_secret_expiration_days + 1) * 24}h")) : null
  
  # Render a template of available cluster sizes
  cluster_size_template = jsondecode(templatefile("${path.module}/cluster_size.tpl", {}))

  cluster_size_rendered = {
    for key in keys(local.cluster_size_template) :
    key => local.cluster_size_template[key]
  }

  node_group_definitions = local.cluster_size_rendered[var.logscale_cluster_size]

  resource_name_prefix = "z${random_string.name-modifier.result}-${var.resource_name_prefix}"

  # This is here because the subnets are configurable
  temp_vnet_list = [ module.azure-core.logscale_digest_nodes_subnet_id, module.azure-core.logscale_ui_nodes_subnet_id, module.azure-core.logscale_ingest_nodes_subnet_id  ]
  subnets_allowed_storage_account_access = [for entry in local.temp_vnet_list : entry if length(entry) > 0 ] 

  
}
