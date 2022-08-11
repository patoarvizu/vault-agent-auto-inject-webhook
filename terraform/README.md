<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.8.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.8.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_deployment.vault_agent_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_horizontal_pod_autoscaler_v1.vault_agent_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/horizontal_pod_autoscaler_v1) | resource |
| [kubernetes_manifest.certificate_vault_agent_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.servicemonitor_vault_agent_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_mutating_webhook_configuration_v1.vault_agent_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/mutating_webhook_configuration_v1) | resource |
| [kubernetes_namespace.ns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_pod_disruption_budget_v1.vault_agent_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/pod_disruption_budget_v1) | resource |
| [kubernetes_service.vault_agent_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service.vault_agent_webhook_metrics](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service_account.vault_agent_webhook](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_namespace.ns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/namespace) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_annotation_prefix"></a> [annotation\_prefix](#input\_annotation\_prefix) | The value to be passed to the -annotation-prefix flag. | `string` | `"vault.patoarvizu.dev"` | no |
| <a name="input_ca_cert_secret_name"></a> [ca\_cert\_secret\_name](#input\_ca\_cert\_secret\_name) | The value to be passed to the -ca-cert-secret-name flag. | `string` | `"vault-tls"` | no |
| <a name="input_cert_manager"></a> [cert\_manager](#input\_cert\_manager) | Object to configure the Certificate object (if one is being created). | <pre>object({<br>    api_version = string<br>    duration = string<br>    renew_before = string<br>    issuer_ref = object(<br>      {<br>        name = string<br>        kind = string<br>      }<br>    )<br>  })</pre> | <pre>{<br>  "api_version": "cert-manager.io/v1",<br>  "duration": "2160h",<br>  "issuer_ref": {<br>    "kind": "ClusterIssuer",<br>    "name": "selfsigning-issuer"<br>  },<br>  "renew_before": "360h"<br>}</pre> | no |
| <a name="input_cert_manager_enable"></a> [cert\_manager\_enable](#input\_cert\_manager\_enable) | If true, a Certificate object will be created and mounted on the pods. **NOTE:** this requires cert-manager to be running on the target cluster. | `bool` | `true` | no |
| <a name="input_certificate_secret_name"></a> [certificate\_secret\_name](#input\_certificate\_secret\_name) | The name of the Secret to be referenced from the Deployment object to mount as the certificate. | `string` | `"vault-agent-webhook"` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | The value to be passed to the -cpu-limit flag. | `string` | `"100m"` | no |
| <a name="input_cpu_request"></a> [cpu\_request](#input\_cpu\_request) | The value to be passed to the -cpu-request flag. | `string` | `"50m"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | If true, a new namespace will be created with the name set to the value of the namespace\_name variable. If false, it will look up an existing namespace with the name of the value of the namespace\_name variable. | `bool` | `true` | no |
| <a name="input_default_config_map_name"></a> [default\_config\_map\_name](#input\_default\_config\_map\_name) | The value to be passed to the -default-config-map-name flag. | `string` | `"vault-agent-config"` | no |
| <a name="input_failure_policy"></a> [failure\_policy](#input\_failure\_policy) | The value of failurePolicy to set on the MutatingWebhookConfiguration object. | `string` | `"Ignore"` | no |
| <a name="input_gomplate_image"></a> [gomplate\_image](#input\_gomplate\_image) | The value to be passed to the -gomplate-image flag. | `string` | `"hairyhenderson/gomplate:v3"` | no |
| <a name="input_hpa"></a> [hpa](#input\_hpa) | Object to configure the HorizontalPodAutoscaler object (if one is being created). | <pre>object({<br>    min_replicas = number<br>    max_replicas = number<br>    cpu_average_utilization = number<br>  })</pre> | <pre>{<br>  "cpu_average_utilization": 80,<br>  "max_replicas": 20,<br>  "min_replicas": 3<br>}</pre> | no |
| <a name="input_hpa_enable"></a> [hpa\_enable](#input\_hpa\_enable) | If set to true, a HorizontalPodAutoscaler object will be created. | `bool` | `false` | no |
| <a name="input_image_pull_policy"></a> [image\_pull\_policy](#input\_image\_pull\_policy) | The value of imagePullPolicy to set on the Deployment object. | `string` | `"IfNotPresent"` | no |
| <a name="input_image_version"></a> [image\_version](#input\_image\_version) | The label of the image to run. | `string` | n/a | yes |
| <a name="input_kubernetes_auth_path"></a> [kubernetes\_auth\_path](#input\_kubernetes\_auth\_path) | The value to be passed to the -kubernetes-auth-path flag. | `string` | `"auth/kubernetes"` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | The value to be passed to the -memory-limit flag. | `string` | `"256Mi"` | no |
| <a name="input_memory_request"></a> [memory\_request](#input\_memory\_request) | The value to be passed to the -memory-request flag. | `string` | `"128Mi"` | no |
| <a name="input_namespace_labels"></a> [namespace\_labels](#input\_namespace\_labels) | The set of labels to add to the namespace (if one needs to be created). | `map` | `{}` | no |
| <a name="input_namespace_name"></a> [namespace\_name](#input\_namespace\_name) | The name of the namespace to create or look up. | `string` | `"vault"` | no |
| <a name="input_pdb_max_unavaiable"></a> [pdb\_max\_unavaiable](#input\_pdb\_max\_unavaiable) | The value of maxUnavailable to set on the PodDisruptionBudget object. | `number` | `0` | no |
| <a name="input_replicas"></a> [replicas](#input\_replicas) | The number of replicas of the webhook server to run. | `number` | `3` | no |
| <a name="input_service_monitor_custom_labels"></a> [service\_monitor\_custom\_labels](#input\_service\_monitor\_custom\_labels) | Custom labels to add to the `ServiceMonitor` object. | `map` | `{}` | no |
| <a name="input_service_monitor_enable"></a> [service\_monitor\_enable](#input\_service\_monitor\_enable) | If true a ServiceMonitor object will be created, and a /metrics endpoint will be exposed. **NOTE:** this requires the Prometheus operator to be running on the target cluster. | `bool` | `true` | no |
| <a name="input_target_vault_address"></a> [target\_vault\_address](#input\_target\_vault\_address) | The value to be passed to the -target-vault-address flag. | `string` | `"https://vault:8200"` | no |
| <a name="input_vault_image_version"></a> [vault\_image\_version](#input\_vault\_image\_version) | The value to be passed to the -vault-image-version flag. | `string` | `"1.4.0"` | no |
| <a name="input_webhook_namespace_selector_expressions"></a> [webhook\_namespace\_selector\_expressions](#input\_webhook\_namespace\_selector\_expressions) | The list of expressions to match the namespaces where this webhook will operate. | <pre>list(object({<br>    key = string<br>    operator = string<br>  }))</pre> | <pre>[<br>  {<br>    "key": "vault-control-plane",<br>    "operator": "DoesNotExist"<br>  }<br>]</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->