# This resource sets up a small container that provisions disk. This is done as a daemonset to guarantee execution
# on every target node (NVME-backed) nodes. The pod is kept running forever to prevent a restart loop on the host.
# It could be possible to change this out with a kuberenetes_job or kubernetes_cron_job resource.
resource "kubernetes_daemonset" "lvm-setup" {
  metadata {
    name          = "${var.name_prefix}-lvm-setup"
    namespace     = kubernetes_namespace.logscale-topo.metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        name = "lvm-setup"
      }
    }

    template {
      metadata {
        labels = {
          name = "lvm-setup"
        }
      }
      spec {
        node_selector = {
          "k8s-app" = "logscale-digest"
        }

        automount_service_account_token = false
        host_pid = true
        
        container {
          name = "lvm-setup"
          image = "debian:bookworm-slim"
          command = [
            "/bin/bash",
            "-c",
            <<-EOT
              apt-get update && apt-get install -y lvm2
              for disk in $(ls /dev/nvme*n*); do pvcreate $disk || true; done
              vgcreate nvme-vg $(ls /dev/nvme*n*) || true
              lvcreate -l 100%FREE -n lv-storage nvme-vg || true
              sleep infinity
            EOT
          ]
          security_context {
            # privileged mode is necessary due to this container needing to modify
            # disks for the underlying node.
            privileged = true
            capabilities {
                add   = ["CAP_SYS_ADMIN", "CAP_SYS_RAWIO", "CAP_DAC_READ_SEARCH", "CAP_LINUX_IMMUTABLE"]
                drop  = ["ALL"]
            }
            seccomp_profile {
              type = "RuntimeDefault"
            }
          }
          volume_mount {
            name = "host-root"
            mount_path = "/root"
          }
          resources {
            limits = {
              memory = "200Mi"
              cpu = "100m"
            }
            requests = {
              memory = "200Mi"
              cpu = "100m"
            }
          }
        
        }
        volume {
          name = "host-root"
          host_path {
            path = "/"
          }
        }
      }
    }
  }
}

# Topo LVM Controller Install
resource "helm_release" "topo_lvm_sc" {
  name             = "${var.name_prefix}-topo-lvm"

  repository       = "https://topolvm.github.io/topolvm"
  chart            = "topolvm"
  namespace        = kubernetes_namespace.logscale-topo.metadata[0].name
  create_namespace = false
  wait             = "false"
  version          = var.topo_lvm_chart_version

  values = [
    file(join("/", [path.module, "helm_values", "topo_lvm_sc.yaml"]))
  ]

  depends_on = [
    kubernetes_daemonset.lvm-setup
  ]
}
