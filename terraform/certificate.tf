resource kubernetes_manifest certificate_vault_agent_webhook {
  for_each = var.cert_manager_enable ? {"certificate": true} : {}
  manifest = {
    apiVersion = var.cert_manager.api_version
    kind = "Certificate"
    metadata = {
      name = "vault-agent-webhook"
      namespace = var.create_namespace ? kubernetes_namespace.ns["ns"].metadata[0].name : data.kubernetes_namespace.ns["ns"].metadata[0].name
    }
    spec = {
      commonName = "vault-agent-webhook"
      dnsNames = [
        "vault-agent-webhook",
        format("vault-agent-webhook.%s", var.namespace),
        format("vault-agent-webhook.%s.svc", var.namespace),
      ]
      duration = var.cert_manager.duration
      issuerRef = {
        kind = var.cert_manager.issuer_ref.kind
        name = var.cert_manager.issuer_ref.name
      }
      renewBefore = var.cert_manager.renew_before
      secretName = var.certificate_secret_name
    }
  }
}