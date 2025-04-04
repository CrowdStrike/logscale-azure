

variable "cm_crds_url" {
  description = "Cert Manager CRDs URL"
  type        = string
  default     = "https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.crds.yaml"
}

variable "humio_operator_version" {
  description = "Humio Operator version"
  type        = string
}

variable "k8s_config_path" {
  description = "The path to k8s configuration."
}

variable "k8s_config_context" {
  description = "Configuration context name, typically the kubernetes server name."
}

variable "strimzi_operator_version" {
  description = "Used to get CRDs for strimzi and install them."
  type = string
}
