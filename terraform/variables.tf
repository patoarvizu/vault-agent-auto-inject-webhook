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

variable annotation_prefix {
  type = string
  default = "vault.patoarvizu.dev"
  description = "The value to be passed to the -annotation-prefix flag."
}

variable target_vault_address {
  type = string
  default = "https://vault:8200"
  description = "The value to be passed to the -target-vault-address flag."
}

variable gomplate_image {
  type = string
  default = "hairyhenderson/gomplate:v3"
  description = "The value to be passed to the -gomplate-image flag."
}

variable kubernetes_auth_path {
  type = string
  default = "auth/kubernetes"
  description = "The value to be passed to the -kubernetes-auth-path flag."
}

variable vault_image_version {
  type = string
  default = "1.4.0"
  description = "The value to be passed to the -vault-image-version flag."
}

variable default_config_map_name {
  type = string
  default = "vault-agent-config"
  description = "The value to be passed to the -default-config-map-name flag."
}

variable ca_cert_secret_name {
  type = string
  default = "vault-tls"
  description = "The value to be passed to the -ca-cert-secret-name flag."
}

variable cpu_request {
  type = string
  default = "50m"
  description = "The value to be passed to the -cpu-request flag."
}

variable memory_request {
  type = string
  default = "128Mi"
  description = "The value to be passed to the -memory-request flag."
}

variable cpu_limit {
  type = string
  default = "100m"
  description = "The value to be passed to the -cpu-limit flag."
}

variable memory_limit {
  type = string
  default = "256Mi"
  description = "The value to be passed to the -memory-limit flag."
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