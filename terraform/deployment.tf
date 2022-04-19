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
            var.flags.ca_cert_secret_name,
            "-vault-image-version",
            var.flags.vault_image_version,
            "-annotation-prefix",
            var.flags.annotation_prefix,
            "-target-vault-address",
            var.flags.target_vault_address,
            "-gomplate-image",
            var.flags.gomplate_image,
            "-kubernetes-auth-path",
            var.flags.kubernetes_auth_path,
            "-default-config-map-name",
            var.flags.default_config_map_name,
            "-cpu-request",
            var.flags.cpu_requests,
            "-cpu-limit",
            var.flags.cpu_limits,
            "-memory-request",
            var.flags.memory_requests,
            "-memory-limit",
            var.flags.memory_limits,
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