resource kubernetes_pod_disruption_budget_v1 vault_agent_webhook {
  metadata {
    name = "vault-agent-webhook"
    namespace = var.create_namespace ? kubernetes_namespace.ns["ns"].metadata[0].name : data.kubernetes_namespace.ns["ns"].metadata[0].name
  }
  spec {
    max_unavailable = var.pdb_max_unavaiable
    selector {
      match_labels = {
        app = "vault-agent-webhook"
      }
    }
  }
}