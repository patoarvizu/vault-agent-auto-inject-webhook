# Vault agent auto-inject webhook

## Intro

This webhook is a companion to the [`vault-dynamic-configuration-operator`](https://github.com/patoarvizu/vault-dynamic-configuration-operator) but it can be deployed indepentendly as a Kubernetes [Mutating Webhook](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/), that can modify Pods to automatically inject a Vault agent sidecar, including a rendered configuration template taken from a `ConfigMap` corresponding to the service's identity, as well as modify the environment variables on all containers in the Pod to inject a `VAULT_ADDR` environment variable that points to the sidecar agent. To do this, annotate your workload (`Deployment`, `StatefulSet`, `DaemonSet`, etc.) with `vault.patoarvizu.dev/agent-auto-inject: sidecar` to have the webhook modify the generated Pods as they are created.

### Running the webhook

The webhook can be run as a `Deployment` on the same cluster, as long as it's exposed as a `Service`, and accepts TLS connections. More details on how to deploy mutating webhooks in Kubernetes can be found on the link above, but this section will cover high-level details.

Your `Deployment` and `Service` will look like those of any other service you run in your cluster. One important difference is that this service has to serve TLS, so the `-tls-cert-file`, and `-tls-key-file` parameters have to be supplied. Your `Deployment` manifest will look something like this:

```yaml
kind: Deployment
...
      containers:
        - name: vault-agent-auto-inject-webhook
          image: patoarvizu/vault-agent-auto-inject-webhook:latest
          command:
          - /vault-dynamic-configuration-webhook
          - -tls-cert-file
          - /tls/tls.crt
          - -tls-key-file
          - /tls/tls.key
          ports:
          - name: https
            containerPort: 4443
          volumeMounts:
            - name: tls
              mountPath: /tls
      volumes:
      - name: tls
        secret:
          secretName: vault-agent-auto-inject-webhook
```

This assumes that there is a `Secret` called `vault-agent-auto-inject-webhook` that contains the `tls.crt` and `tls.key` files that can be mounted on the container and passed to the webhook. The [`cert-manager`](https://github.com/jetstack/cert-manager/) project makes it really easy to generate certificates as Kubernetes `Secret`s to be used for cases like this.

### Configuring the webhook

The other important piece is deploying the `MutatingWebhookConfiguration` itself, which would look like this:

```yaml
apiVersion: admissionregistration.k8s.io/v1beta1
kind: MutatingWebhookConfiguration
metadata:
  name: vault-agent-auto-inject-webhook
  labels:
    app: vault-agent-auto-inject-webhook
webhooks:
  - name: vault.patoarvizu.dev
    rules:
      - apiGroups:
          - ""
        apiVersions:
          - v1
        operations:
          - CREATE
          - UPDATE
        resources:
          - pods
    failurePolicy: Ignore
    clientConfig:
      caBundle: ${CA_BUNDLE}
      service:
        name: vault-agent-auto-inject-webhook
        namespace: default
        path: /
```

The `clientConfig` map field should match the `Service` that sits in front of your `Deployment` from above. Notice that the `caBundle` field only contains the `${CA_BUNDLE}` placeholder. The actual value of this should be the base64-encoded public CA certificate that signed the `tls.crt` that your webhook is running with, which will depend on how those certificates were generated.

**TIP:** If you created the webhook certificates above using `cert-manager`, you can use the [`cert-manager.io/inject-ca-from` annotation](https://docs.cert-manager.io/en/latest/reference/cainjector.html) on the `MutatingWebhookConfiguration` and `cert-manager` will automatically inject the corresponding CA cert into the object.

### Webhook command-line flags

Flag | Description | Default
-----|-------------|--------
`-tls-cert-file` | TLS certificate file |
`-tls-key-file` | TLS key file |
`-annotation-prefix` | Prefix of the annotations the webhook will process | `vault.patoarvizu.dev`
`-target-vault-address` | Address of remote Vault API | `https://vault:8200`
`-kubernetes-auth-path` | Path to Vault Kubernetes auth endpoint | `auth/kubernetes`
`-vault-image-version` | Tag on the 'vault' Docker image to inject with the sidecar | `1.3.0`
`-default-config-map-name` | The name of the ConfigMap to be used for the Vault agent configuration by default, unless overwritten by annotation | `vault-agent-config`
`-cpu-request` | The amount of CPU units to request for the Vault agent sidecar") | `50m`
`-cpu-limit` | The amount of CPU units to limit to on the Vault agent sidecar") | `100m`
`-memory-request` | The amount of memory units to request for the Vault agent sidecar") | `128Mi`
`-memory-limit` | The amount of memory units to limit to on the Vault agent sidecar") | `256Mi`
`-listen-addr` | The address to start the server | `:4443`

### ConfigMap

The webhook expects that a `ConfigMap` named `vault-agent-config` (or something else, if the `-default-config-map-name` was passed to the server) will exist in the same namespace as the target Pod (**NOT** in the same namespace as the webhook itself), that will contain only one key, called `vault-agent-config.hcl`, which will contain a [Go template](https://golang.org/pkg/text/template/) that will be rendered into the Vault agent configuration using [`gomplate`](https://github.com/hairyhenderson/gomplate), and will have the following environment variables available to be discovered with the `getenv` function:

Environment variable | Value
---------------------|------
`SERVICE` | The name of the `ServiceAccount` attached to the pod
`TARGET_VAULT_ADDRESS` | The value of the `-target-vault-address` parameter (or its default)
`KUBERNETES_AUTH_PATH` | The value of the `-kubernetes-auth-path` parameter (or its default)

## Init containers

Alternatively, the webhook can inject the Vault agent as an init container instead of a sidecar, which is useful for short-lived workloads, like `Job`s and `CronJob`s. In that case, the init container should use a configuration that has `exit_after_auth = true` so the init container exists after authenticating and doesn't remain long-lived. Doing so, would cause the container to never exit past the init container phase. The config file should also contain at least one [file sink](https://www.vaultproject.io/docs/agent/autoauth/sinks/file.html). The webhook will also modify the containers to mount an additional volume on `/vault-agent` that can be used as a file sink.

To do this, annotate your workload with `vault.patoarvizu.dev/agent-auto-inject: init-container`.

Usually, a given config file will only be suitable for either long-lived sidecars or short-lived init containers. If the default config map (`vault-agent-config` by default, or the overwrite if `-default-config-map-name` was provided) is not suitable for a specific application, it can be overwritten with the `vault.patoarvizu.dev/agent-config-map` annotation. If set, the value should be the name of a `ConfigMap` in the same namespace that that the webhook should use to inject, instead of the default one.