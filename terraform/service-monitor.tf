resource kubernetes_manifest servicemonitor_vault_agent_webhook {
  for_each = var.service_monitor_enable ? {"service-monitor": true} : {}
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind = "ServiceMonitor"
    metadata = {
      name = "vault-agent-webhook"
      namespace = var.create_namespace ? kubernetes_namespace.ns["ns"].metadata[0].name : data.kubernetes_namespace.ns["ns"].metadata[0].name
      labels = var.service_monitor_custom_labels
    }
    spec = {
      endpoints = [
        {
          path = "/"
          port = "metrics"
        },
      ]
      selector = {
        matchLabels = {
          app = "vault-agent-webhook"
        }
      }
    }
  }
}
