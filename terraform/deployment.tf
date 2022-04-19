resource kubernetes_deployment vault_agent_webhook {
  metadata {
    name = "vault-agent-webhook"
    namespace = var.create_namespace ? kubernetes_namespace.ns["ns"].metadata[0].name : data.kubernetes_namespace.ns["ns"].metadata[0].name
  }
  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        app = "vault-agent-webhook"
      }
    }
    template {
      metadata {
        labels = {
          app = "vault-agent-webhook"
        }
      }
      spec {
        container {
          command = [
            "/vault-agent-auto-inject-webhook",
            "-tls-cert-file",
            "/tls/tls.crt",
            "-tls-key-file",
            "/tls/tls.key",
            "-ca-cert-secret-name",
            var.ca_cert_secret_name,
            "-vault-image-version",
            var.vault_image_version,
            "-annotation-prefix",
            var.annotation_prefix,
            "-target-vault-address",
            var.target_vault_address,
            "-gomplate-image",
            var.gomplate_image,
            "-kubernetes-auth-path",
            var.kubernetes_auth_path,
            "-default-config-map-name",
            var.default_config_map_name,
            "-cpu-request",
            var.cpu_request,
            "-cpu-limit",
            var.cpu_limit,
            "-memory-request",
            var.memory_request,
            "-memory-limit",
            var.memory_limit,
            "-mount-ca-cert-secret",
          ]
          image = format("patoarvizu/vault-agent-auto-inject-webhook:%s", var.image_version)
          image_pull_policy = var.image_pull_policy
          name = "vault-agent-webhook"
          port {
            container_port = 4443
            name = "https"
          }
          dynamic "port" {
            for_each = var.service_monitor_enable ? {metrics: true} : {}
            content {
              container_port = 8081
              name = "metrics"
            }
          }
          volume_mount {
            mount_path = "/tls"
            name = "tls"
          }
        }
        service_account_name = kubernetes_service_account.vault_agent_webhook.metadata[0].name
        volume {
          name = "tls"
          secret {
            secret_name = var.certificate_secret_name
          }
        }
      }
    }
  }
}