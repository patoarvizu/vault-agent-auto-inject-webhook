variable create_namespace {
  type = bool
  default = true
}

variable namespace {
  type = string
  default = "vault"
}

variable namespace_labels {
  type = map
  default = {}
}

variable replicas {
  type = number
  default = 3
}

variable image_version {
  type = string
}

variable image_pull_policy {
  type = string
  default = "IfNotPresent"
}

variable failure_policy {
  type = string
  default = "Ignore"
}

variable pdb_max_unavaiable {
  type = number
  default = 0
}

variable hpa_enable {
  type = bool
  default = true
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
}

variable certificate_secret_name {
  type = string
  default = "vault-agent-webhook"
}

variable cert_manager_enable {
  type = bool
  default = true
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
    duration = "2160h0m0s"
    renew_before = "360h0m0s"
    issuer_ref = {
      name = "selfsigning-issuer"
      kind = "ClusterIssuer"
    }
  }
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
}

variable service_monitor_enable {
  type = bool
  default = true
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
}