# vault-agent-auto-inject-webhook

![Version: 0.2.1](https://img.shields.io/badge/Version-0.2.1-informational?style=flat-square)

Vault agent auto-inject webhook

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | string | `nil` | Affinity/anti-affinity rules for pod scheduling according to the [documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity). This map will be set as is on the Deployment object. |
| caBundle | string | `"Cg=="` | The base64-encoded public CA certificate to be set on the `MutatingWebhookConfiguration`. Note that it defaults to `Cg==` which is a base64-encoded empty string. If this value is not automatically set by cert-manager, or some other mutating webhook, this should be set explicitly. |
| certManager.apiVersion | string | `"cert-manager.io/v1alpha2"` | The `apiVersion` of the `Certificate` object created by the chart. It depends on the versions made available by the specific cert-manager running on the cluster. |
| certManager.duration | string | `"2160h"` | The value to be set directly on the `duration` field of the `Certificate`. |
| certManager.injectSecret | bool | `true` | Enables auto-injection of a certificate managed by [cert-manager](https://github.com/jetstack/cert-manager). |
| certManager.issuerRef | object | `{"kind":"ClusterIssuer","name":"selfsigning-issuer"}` | The `name` and `kind` of the cert-manager issuer to be used. |
| certManager.renewBefore | string | `"360h"` | The value to be set directly on the `renewBefore` field of the `Certificate`. |
| failurePolicy | string | `"Ignore"` | The value to set directly on the `failurePolicy` of the `MutatingWebhookConfiguration`. Valid values are `Fail` or `Ignore`. |
| flags.annotationPrefix | string | `"vault.patoarvizu.dev"` | The value to be set on the `-annotation-prefix` flag. |
| flags.caCertSecretName | string | `"vault-tls"` | The value to be set on the `-ca-cert-secret-name` flag. |
| flags.defaultConfigMapName | string | `"vault-agent-config"` | The value to be set on the `-default-config-map-name` flag. |
| flags.gomplateImage | string | `"hairyhenderson/gomplate:v3"` | The value to be set to the `-gomplate-image` flag. |
| flags.kubernetesAuthPath | string | `"auth/kubernetes"` | The value to be set on the `-kubernetes-auth-path` flag. |
| flags.mountCACertSecret | bool | `true` | The value to be set on the `-mount-ca-cert-secret` flag. |
| flags.resources.limits.cpu | string | `"100m"` | The value to be set on the `-cpu-limit` flag. |
| flags.resources.limits.memory | string | `"256Mi"` | The value to be set on the `-memory-limit` flag. |
| flags.resources.requests.cpu | string | `"50m"` | The value to be set on the `-cpu-request` flag. |
| flags.resources.requests.memory | string | `"128Mi"` | The value to be set on the `-memory-request` flag. |
| flags.targetVaultAddress | string | `nil` | The value to be set on the `-target-vault-address` flag. If not specified, it will default to https://vault.{{ .Release.Namespace }}:8200. |
| flags.vaultImageVersion | string | `"1.4.0"` | The value to be set on the `-vault-image-version` flag. |
| hpa.apiVersion | string | `"autoscaling/v2beta2"` | The `apiVersion` of the `HorizontalPodAutoscaler` to create. The metrics configuration options vary depending on this value. |
| hpa.enable | bool | `false` | Create a `HorizontalPodAutoscaler` object to control dynamic replication of the webhook. If this is set to `false`, all values under `hpa` are ignored. |
| hpa.maxReplicas | int | `20` | The maximum number of replicas to attempt to maintain at all times. |
| hpa.metricsScalingConfiguration | list | `[{"resource":{"name":"cpu","target":{"averageUtilization":80,"type":"Utilization"}},"type":"Resource"}]` | The scaling configuration to be injected directly into the `HorizontalPodAutoscaler` object. |
| hpa.minReplicas | int | `3` | The minimum number of replicas to attempt to maintain at all times. |
| imagePullPolicy | string | `"IfNotPresent"` | The imagePullPolicy to be used on the webhook. |
| imageVersion | string | `"v0.5.0"` | The image version used for the webhook. |
| namespaceSelector | object | `{"matchExpressions":[{"key":"vault-control-plane","operator":"DoesNotExist"}]}` | A label selector expression to determine what namespaces should be in scope for the mutating webhook. |
| podDisruptionBudget.availability.maxUnavailable | int | `0` | The default availability is set to `maxUnavailable: 0` (if `podDisruptionBudget.enable` is `true`). |
| podDisruptionBudget.enable | bool | `true` | Create a `PodDisruptionBudget` object to control replication availability. You can find more info about disruption budgets in Kubernetes [here](https://kubernetes.io/docs/tasks/run-application/configure-pdb/).  |
| prometheusMonitoring.enable | bool | `true` | Create the `Service` and `ServiceMonitor` objects to enable Prometheus monitoring on the webhook. |
| prometheusMonitoring.serviceMonitor.customLabels | string | `nil` | Custom labels to add to the ServiceMonitor object. |
| replicas | int | `3` | The number of replicas of the webhook to run. |
| resources | string | `nil` | Map of cpu/memory resources and limits, to be set on the webhook |
| serviceAccount.name | string | `"vault-agent-webhook"` | The name of the `ServiceAccount` to be created. |
| tls.mountPath | string | `"/tls"` | The path where the CA cert from the secret should be mounted. |
| tls.secretName | string | `"vault-agent-webhook"` | The name of the `Secret` from which the CA cert will be mounted. This value is ignored if `.certManager.injectSecret` is set to `true`. |
