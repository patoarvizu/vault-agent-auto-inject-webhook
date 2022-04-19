############
# Required #
############

variable image_version {
  type = string
  description = "The label of the image to run."
}

############
# Optional #
############

variable create_namespace {
  type = bool
  default = true
  description = "If true, a new namespace will be created with the name set to the value of the namespace_name variable. If false, it will look up an existing namespace with the name of the value of the namespace_name variable."
}

variable namespace_name {
  type = string
  default = "vault"
  description = "The name of the namespace to create or look up."
}

variable namespace_labels {
  type = map
  default = {}
  description = "The set of labels to add to the namespace (if one needs to be created)."
}

variable replicas {
  type = number
  default = 3
  description = "The number of replicas of the webhook server to run."
}

variable image_pull_policy {
  type = string
  default = "IfNotPresent"
  description = "The value of imagePullPolicy to set on the Deployment object."
}

variable failure_policy {
  type = string
  default = "Ignore"
  description = "The value of failurePolicy to set on the MutatingWebhookConfiguration object."
}

variable pdb_max_unavaiable {
  type = number
  default = 0
  description = "The value of maxUnavailable to set on the PodDisruptionBudget object."
}

variable hpa_enable {
  type = bool
  default = true
  description = "If set to true, a HorizontalPodAutoscaler object will be created."
}

variable hpa {
  type = object({
    min_replicas = number
    max_replicas = number
    cpu_average_utilization = number
  })
  default = {
    min_replicas = 3
    max_replicas = 20
    cpu_average_utilization = 80
  }
  description = "Object to configure the HorizontalPodAutoscaler object (if one is being created)."
}

variable certificate_secret_name {
  type = string
  default = "vault-agent-webhook"
  description = "The name of the Secret to be referenced from the Deployment object to mount as the certificate."
}

variable cert_manager_enable {
  type = bool
  default = true
  description = "If true, a Certificate object will be created and mounted on the pods. **NOTE:** this requires cert-manager to be running on the target cluster."
}

variable cert_manager {
  type = object({
    api_version = string
    duration = string
    renew_before = string
    issuer_ref = object(
      {
        name = string
        kind = string
      }
    )
  })
  default = {
    api_version = "cert-manager.io/v1"
    duration = "2160h"
    renew_before = "360h"
    issuer_ref = {
      name = "selfsigning-issuer"
      kind = "ClusterIssuer"
    }
  }
  description = "Object to configure the Certificate object (if one is being created)."
}

variable flags {
  type = object({
    annotation_prefix = string
    target_vault_address = string
    gomplate_image = string
    kubernetes_auth_path = string
    vault_image_version = string
    default_config_map_name = string
    ca_cert_secret_name = string
    cpu_requests = string
    memory_requests = string
    cpu_limits = string
    memory_limits = string
  })
  default = {
    annotation_prefix = "vault.patoarvizu.dev"
    target_vault_address = "https://vault:8200"
    gomplate_image = "hairyhenderson/gomplate:v3"
    kubernetes_auth_path = "auth/kubernetes"
    vault_image_version = "1.4.0"
    default_config_map_name = "vault-agent-config"
    mount_ca_cert_secret = true
    ca_cert_secret_name = "vault-tls"
    cpu_requests = "50m"
    memory_requests = "128Mi"
    cpu_limits = "100m"
    memory_limits = "256Mi"
  }
  description = "Set of flags to pass to the webhook workload. **NOTE:** since this is a variable of type object and given the constraints of the Terraform language, if you overwrite one you'll still need to pass the full object."
}

variable service_monitor_enable {
  type = bool
  default = true
  description = "If true a ServiceMonitor object will be created, and a /metrics endpoint will be exposed. **NOTE:** this requires the Prometheus operator to be running on the target cluster."
}

variable webhook_namespace_selector_expressions {
  type = list(object({
    key = string
    operator = string
  }))
  default = [
    {
      key: "vault-control-plane"
      operator: "DoesNotExist"
    }
  ]
  description = "The list of expressions to match the namespaces where this webhook will operate."
}