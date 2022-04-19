resource kubernetes_horizontal_pod_autoscaler_v1 vault_agent_webhook {
  for_each = var.hpa_enable ? {"hpa": true} : {}
  metadata {
    name = "vault-agent-webhook"
    namespace = var.create_namespace ? kubernetes_namespace.ns["ns"].metadata[0].name : data.kubernetes_namespace.ns["ns"].metadata[0].name
  }
  spec {
    min_replicas = var.hpa.min_replicas
    max_replicas = var.hpa.max_replicas
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment.vault_agent_webhook.metadata[0].name
    }
    target_cpu_utilization_percentage = var.hpa.cpu_average_utilization
  }
}