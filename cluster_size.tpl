${jsonencode(
{
    // This template specifies the available parameters for the different sizes of LogScale clusters
    // system_node          -> AKS system nodes for running system pod functions like coredns
    // logscale_digest      -> AKS nodes dedicated to core logscale systems (NVME attached storage) 
    // logscale_ingress     -> AKS nodes dedicated to proxy for access to control system access 
    // logscale_ingest      -> AKS nodes dedicated to logscale ingest nodes
    // logscale_ui          -> AKS nodes dedicated to UI nodes that do not handle data digest
    // strimzi_node         -> AKS nodes dedicated to strimzi kafka

    "xsmall": {
        // system nodes
        "system_node_min_node_count": 2,
        "system_node_max_node_count": 5,
        "system_node_desired_node_count": 2,
        "system_node_instance_type": "Standard_F4s_v2",
        "system_node_root_disk_size": 40,

        // kafka nodes
        "strimzi_node_instance_type": "Standard_L8s_v3", // Need NVMe disks for TopoLVM
        "strimzi_node_min_node_count": 3,
        "strimzi_node_max_node_count": 5,
        "strimzi_node_desired_node_count": 3,
        "strimzi_node_root_disk_size": 40,

        // digest nodes
        "logscale_digest_instance_type": "Standard_L8s_v3", // Need NVMe disks for Topo LVM
        "logscale_digest_root_disk_size": 40,
        "logscale_digest_min_node_count": 3,
        "logscale_digest_max_node_count": 3,
        "logscale_digest_desired_node_count": 3,

        // ingest nodes
        "logscale_ingest_min_node_count": 3,
        "logscale_ingest_max_node_count": 5,
        "logscale_ingest_desired_node_count": 3,
        "logscale_ingest_instance_type": "Standard_L8s_v3",  // Need NVMe disks for Topo LVM
        "logscale_ingest_root_disk_size": 40,

        // ingress nodes
        "logscale_ingress_min_node_count": 2,
        "logscale_ingress_max_node_count": 3,
        "logscale_ingress_desired_node_count": 2,
        "logscale_ingress_instance_type": "Standard_F4s_v2",
        "logscale_ingress_root_disk_size": 40,

        // ui nodes
        "logscale_ui_min_node_count": 1,
        "logscale_ui_max_node_count": 3,
        "logscale_ui_desired_node_count": 2,
        "logscale_ui_instance_type": "Standard_L8s_v3", // Need NVMe disks for Topo LVM
        "logscale_ui_root_disk_size": 40,
    },

    "small": {
        // system nodes
        "system_node_min_node_count": 2,
        "system_node_max_node_count": 5,
        "system_node_desired_node_count": 3,
        "system_node_instance_type": "Standard_F4s_v2",
        "system_node_root_disk_size": 40,

        // kafka nodes
        "strimzi_node_instance_type": "Standard_L16s_v3",
        "strimzi_node_min_node_count": 5,
        "strimzi_node_max_node_count": 15,
        "strimzi_node_desired_node_count": 5,
        "strimzi_node_root_disk_size": 40,
        "kafka_broker_pod_replica_count": 5,

        // digest nodes
        "logscale_digest_instance_type": "Standard_L16s_v3",
        "logscale_digest_root_disk_size": 40,
        "logscale_digest_min_node_count": 6,
        "logscale_digest_max_node_count": 15,
        "logscale_digest_desired_node_count":6,

        // ingest nodes
        "logscale_ingest_min_node_count": 6,
        "logscale_ingest_max_node_count": 21,
        "logscale_ingest_desired_node_count": 6,
        "logscale_ingest_instance_type": "Standard_L16s_v3",
        "logscale_ingest_root_disk_size": 40,

        // ingress nodes
        "logscale_ingress_min_node_count": 3,
        "logscale_ingress_max_node_count": 21,
        "logscale_ingress_desired_node_count": 3,
        "logscale_ingress_instance_type": "Standard_F4s_v2",
        "logscale_ingress_root_disk_size": 40,

        // ui nodes
        "logscale_ui_min_node_count": 3,
        "logscale_ui_max_node_count": 9,
        "logscale_ui_desired_node_count": 3,
        "logscale_ui_instance_type": "Standard_L8s_v3",
        "logscale_ui_root_disk_size": 40,

    },
    "medium": {
        // system nodes
        "system_node_min_node_count": 2,
        "system_node_max_node_count": 12,
        "system_node_desired_node_count": 3,
        "system_node_instance_type": "Standard_F4s_v2",
        "system_node_root_disk_size": 40,

        // kafka nodes
        "strimzi_node_instance_type": "Standard_L32s_v3",
        "strimzi_node_min_node_count": 7,
        "strimzi_node_max_node_count": 21,
        "strimzi_node_desired_node_count": 15,
        "strimzi_node_root_disk_size": 40,

        // digest nodes
        "logscale_digest_instance_type": "Standard_L16s_v3",
        "logscale_digest_root_disk_size": 40,
        "logscale_digest_min_node_count": 21,
        "logscale_digest_max_node_count": 45,
        "logscale_digest_desired_node_count":21,

        // ingest nodes
        "logscale_ingest_min_node_count": 15,
        "logscale_ingest_max_node_count": 45,
        "logscale_ingest_desired_node_count": 15,
        "logscale_ingest_instance_type": "Standard_L64s_v3",
        "logscale_ingest_root_disk_size": 40,

        // ingress nodes
        "logscale_ingress_min_node_count": 6,
        "logscale_ingress_max_node_count": 33,
        "logscale_ingress_desired_node_count": 6,
        "logscale_ingress_instance_type": "Standard_F8s_v2",
        "logscale_ingress_root_disk_size": 40,
        
        // ui nodes
        "logscale_ui_min_node_count": 6,
        "logscale_ui_max_node_count": 21,
        "logscale_ui_desired_node_count": 6,
        "logscale_ui_instance_type": "Standard_L16s_v3",
        "logscale_ui_root_disk_size": 40,
    },
    "large": {
        // system nodes
        "system_node_min_node_count": 3,
        "system_node_max_node_count": 21,
        "system_node_desired_node_count": 6,
        "system_node_instance_type": "Standard_F8s_v2",
        "system_node_root_disk_size": 40,

        // kafka nodes
        "strimzi_node_instance_type": "Standard_L48s_v3",
        "strimzi_node_min_node_count": 14,
        "strimzi_node_max_node_count": 45,
        "strimzi_node_desired_node_count": 30,
        "strimzi_node_root_disk_size": 40,

        // digest nodes
        "logscale_digest_instance_type": "Standard_L32s_v3",
        "logscale_digest_root_disk_size": 40,
        "logscale_digest_min_node_count": 21,
        "logscale_digest_max_node_count": 60,
        "logscale_digest_desired_node_count":42,

        // ingest nodes
        "logscale_ingest_min_node_count": 15,
        "logscale_ingest_max_node_count": 45,
        "logscale_ingest_desired_node_count": 15,
        "logscale_ingest_instance_type": "Standard_L96s_v3",
        "logscale_ingest_root_disk_size": 40,

        // ingress nodes
        "logscale_ingress_min_node_count": 6,
        "logscale_ingress_max_node_count": 33,
        "logscale_ingress_desired_node_count": 6,
        "logscale_ingress_instance_type": "Standard_F16s_v2",
        "logscale_ingress_root_disk_size": 40,
        
        // ui nodes
        "logscale_ui_min_node_count": 6,
        "logscale_ui_max_node_count": 21,
        "logscale_ui_desired_node_count": 9,
        "logscale_ui_instance_type": "Standard_L32s_v3",
        "logscale_ui_root_disk_size": 40,
    },
    "xlarge": {
        // system nodes
        "system_node_min_node_count": 3,
        "system_node_max_node_count": 21,
        "system_node_desired_node_count": 6,
        "system_node_instance_type": "Standard_F8s_v2",
        "system_node_root_disk_size": 40,

        // kafka nodes
        "strimzi_node_instance_type": "Standard_L64s_v3",
        "strimzi_node_min_node_count": 21,
        "strimzi_node_max_node_count": 45,
        "strimzi_node_desired_node_count": 33,
        "strimzi_node_root_disk_size": 40,

        // digest nodes
        "logscale_digest_instance_type": "Standard_L64s_v3",
        "logscale_digest_root_disk_size": 40,
        "logscale_digest_min_node_count": 26,
        "logscale_digest_max_node_count": 120,
        "logscale_digest_desired_node_count":78,

        // ingest nodes
        "logscale_ingest_min_node_count": 15,
        "logscale_ingest_max_node_count": 45,
        "logscale_ingest_desired_node_count": 18,
        "logscale_ingest_instance_type": "Standard_L48s_v3",
        "logscale_ingest_root_disk_size": 40,


        // ingress nodes
        "logscale_ingress_min_node_count": 9,
        "logscale_ingress_max_node_count": 60,
        "logscale_ingress_desired_node_count": 18,
        "logscale_ingress_instance_type": "Standard_F16s_v2",
        "logscale_ingress_root_disk_size": 40,

        
        // ui nodes
        "logscale_ui_min_node_count": 12,
        "logscale_ui_max_node_count": 30,
        "logscale_ui_desired_node_count": 18,
        "logscale_ui_instance_type": "Standard_L64s_v3",
        "logscale_ui_root_disk_size": 40,
    },
}
)}
