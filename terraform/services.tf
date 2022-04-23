resource kubernetes_service vault_agent_webhook {
  metadata {
    name = "vault-agent-webhook"
    namespace = var.create_namespace ? kubernetes_namespace.ns["ns"].metadata[0].name : data.kubernetes_namespace.ns["ns"].metadata[0].name
  }
  spec {
    port {
      port = 443
      protocol = "TCP"
      target_port = "https"
    }
    selector = {
      app = "vault-agent-webhook"
    }
    type = "ClusterIP"
  }
}

resource kubernetes_service vault_agent_webhook_metrics {
  for_each = var.service_monitor_enable ? {"metrics": true} : {}
  metadata {
    name = "vault-agent-webhook-metrics"
    namespace = var.create_namespace ? kubernetes_namespace.ns["ns"].metadata[0].name : data.kubernetes_namespace.ns["ns"].metadata[0].name
  }
  spec {
    port {
      name = "metrics"
      port = 8081
      protocol = "TCP"
      target_port = "metrics"
    }
    selector = {
      app = "vault-agent-webhook"
    }
    type = "ClusterIP"
  }
}