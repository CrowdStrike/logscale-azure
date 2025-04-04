/**
 * ## Module: kubernetes/crds
 * This module installs custom resource definitions (crds) into the Kubernetes environment and is run in advance of any other
 * kubernetes module to ensure successful terraform planning.
 *
 */

#This bypasses the issue of some of the CRDs existing in advance by applying directly with kubectl
#instead of using terraform resources. It's better than having to manually delete existing resources or import
#them into terraform manually.

resource "null_resource" "install_cert_manager" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${var.cm_crds_url}"
  }
}

# For installing the strimzi crds. This needs to be done in advance to make terraform plans work when building strimzi later.
resource "null_resource" "install_strimzi_crds" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/strimzi/strimzi-kafka-operator/releases/download/${var.strimzi_operator_version}/strimzi-crds-${var.strimzi_operator_version}.yaml"
  }
}

# Humio Operator CRDs
data "http" "humiocluster" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioclusters.yaml"
}

data "http" "humioexternalclusters" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioexternalclusters.yaml"
}

data "http" "humioingesttokens" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioingesttokens.yaml"
}

data "http" "humioparsers" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioparsers.yaml"
}

data "http" "humiorepositories" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiorepositories.yaml"
}

data "http" "humioviews" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioviews.yaml"
}

data "http" "humioalerts" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioalerts.yaml"
}

data "http" "humioactions" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioactions.yaml"
}

data "http" "humioscheduledsearches" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioscheduledsearches.yaml"
}

data "http" "humiofilteralerts" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiofilteralerts.yaml"
}

data "http" "humioaggregatealerts" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humioaggregatealerts.yaml"
}

data "http" "humiobootstraptokens" {
  url = "https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${var.humio_operator_version}/config/crd/bases/core.humio.com_humiobootstraptokens.yaml"
}

# Decode and filter out the 'status' attribute from the CRD manifests
locals {
  crds_manifests = flatten([
    for data in [
      data.http.humiocluster,
      data.http.humioexternalclusters,
      data.http.humioingesttokens,
      data.http.humioparsers,
      data.http.humiorepositories,
      data.http.humioviews,
      data.http.humioalerts,
      data.http.humioactions,
      data.http.humioscheduledsearches,
      data.http.humiofilteralerts,
      data.http.humioaggregatealerts,
      data.http.humiobootstraptokens
      ] : [
      { for k, v in yamldecode(data.response_body) : k => v if k != "status" }
    ]
  ])

  crds_map = {
    for idx, manifest in local.crds_manifests :
    "${manifest.kind}_${manifest.metadata.name}_${idx}" => manifest
  }
}

# Apply each CRD manifest for humio/logscale
resource "kubernetes_manifest" "humio_operator_crds" {
  for_each = local.crds_map
  manifest = each.value


}

