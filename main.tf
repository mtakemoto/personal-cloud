# module "domain" {
#     source = "./domain"
#     domain_name = "takemoto.ai"
# }

module "azure" {
    source = "./azure"
    rg_name = "pcloud_ohia_prod"
    rg_location = "West US 2"
    kv_name = "ohiakvprod"
    k8s_cluster_name = "ohia"
    k8s_vm_size = "standard_b2s"
    k8s_node_count = 1
}