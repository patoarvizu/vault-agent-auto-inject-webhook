resource kubernetes_mutating_webhook_configuration_v1 vault_agent_webhook {
  metadata {
    annotations = {
      "cert-manager.io/inject-ca-from" = format("%s/vault-agent-webhook", var.namespace)
    }
    name = "vault-agent-webhook"
  }
  webhook {
    client_config {
      service {
        name = "vault-agent-webhook"
        namespace = var.create_namespace ? kubernetes_namespace.ns["ns"].metadata[0].name : data.kubernetes_namespace.ns["ns"].metadata[0].name
        path = "/"
      }
    }
    failure_policy = var.failure_policy
    side_effects = "None"
    admission_review_versions = [
      "v1",
      "v1beta1",
    ]
    name = "vault-agent-webhook.patoarvizu.dev"
    dynamic "namespace_selector" {
      for_each = var.webhook_namespace_selector_expressions
      content {
        match_expressions {
          key = namespace_selector.value["key"]
          operator = namespace_selector.value["operator"]
        }
      }
    }
    rule {
      api_groups = [
        "",
      ]
      api_versions = [
        "v1",
      ]
      operations = [
        "CREATE",
        "UPDATE",
      ]
      resources = [
        "pods",
      ]
    }
  }
  lifecycle {
    ignore_changes = [webhook[0].client_config[0].ca_bundle]
  }
}