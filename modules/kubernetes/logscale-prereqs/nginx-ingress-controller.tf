
/*
Deploy a generic nginx ingress controller for accessing logscale services
*/
resource "helm_release" "nginx_ingress" {
    name                    = "${var.name_prefix}-nginx-ingress"
    namespace               = kubernetes_namespace.logscale-ingress.metadata[0].name

    repository             = "https://kubernetes.github.io/ingress-nginx"
    version                 = var.nginx_ingress_helm_chart_version
    chart                   = "ingress-nginx"

    set {
      name                = "controller.service.externalTrafficPolicy"
      value               = "Local"
    }

    set {
      name                = "controller.service.type"
      value               = "LoadBalancer"
    }

    set {
      name                = "controller.service.loadBalancerIP"
      value               = var.logscale_public_ip
    }

    set {
      name                = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"
      value               = var.logscale_lb_internal_only == true ? "true" : "false" 
    }

    set {
      name                = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
      value               = var.resource_group_name
    }

    set {
      name                = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-pip-name"
      value               = var.azure_logscale_ingress_pip_name
    }

    set {
      name                = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-dns-label-name"
      value               = var.azure_logscale_ingress_domain_name_label
    }

    set {
      name                = "controller.autoscaling.enabled"
      value               = "true"
    }

    set {
      name                = "controller.autoscaling.targetCPUUtilizationPercentage"
      value               = "65"
    }
  
    set {
      name                = "controller.autoscaling.targetMemoryUtilizationPercentage"
      value               = "65"
    }

    /* Templatize these items */
    set {
      name                = "controller.replicaCount"
      value               = var.logscale_ingress_pod_count
    }

    set {
      name                = "controller.autoscaling.minReplicas"
      value               = var.logscale_ingress_min_pod_count
    }

    set {
      name                = "controller.autoscaling.maxReplicas"
      value               = var.logscale_ingress_max_pod_count
    }

    set {
      name                = "controller.resources.requests.cpu"
      value               = var.logscale_ingress_resources["requests"]["cpu"]
    }

    set {
      name                = "controller.resources.requests.memory"
      value               = var.logscale_ingress_resources["requests"]["memory"]
    }

    set {
      name                = "controller.resources.limits.cpu"
      value               = var.logscale_ingress_resources["limits"]["cpu"]
    }

    set {
      name                = "controller.resources.limits.memory"
      value               = var.logscale_ingress_resources["limits"]["memory"]
    }
    
    // In cluster type "basic", the controller will exist on the system node
    // In any other cluster type, we're expecting a dedicated node group.
    set {
      name                = "controller.nodeSelector.k8s-app"
      value               = var.logscale_cluster_type == "basic" ? "support" : "ingress"
    }

}