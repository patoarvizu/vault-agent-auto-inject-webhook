# Vault agent auto-inject webhook

![CircleCI](https://img.shields.io/circleci/build/github/patoarvizu/vault-agent-auto-inject-webhook.svg?label=CircleCI) ![GitHub tag (latest SemVer)](https://img.shields.io/github/tag/patoarvizu/vault-agent-auto-inject-webhook.svg) ![Docker Pulls](https://img.shields.io/docker/pulls/patoarvizu/vault-agent-auto-inject-webhook.svg) ![Keybase BTC](https://img.shields.io/keybase/btc/patoarvizu.svg) ![Keybase PGP](https://img.shields.io/keybase/pgp/patoarvizu.svg) ![GitHub](https://img.shields.io/github/license/patoarvizu/vault-agent-auto-inject-webhook.svg)

<!-- TOC -->

- [Vault agent auto-inject webhook](#vault-agent-auto-inject-webhook)
  - [Intro](#intro)
    - [Running the webhook](#running-the-webhook)
    - [Configuring the webhook](#configuring-the-webhook)
    - [Webhook command-line flags](#webhook-command-line-flags)
    - [ConfigMap](#configmap)
    - [Auto-mount CA cert](#auto-mount-ca-cert)
    - [Init containers](#init-containers)
    - [Metrics](#metrics)
    - [Auto-reloading certificate](#auto-reloading-certificate)
  - [For security nerds](#for-security-nerds)
    - [Docker images are signed and published to Docker Hub's Notary server](#docker-images-are-signed-and-published-to-docker-hubs-notary-server)
    - [Docker images are labeled with Git and GPG metadata](#docker-images-are-labeled-with-git-and-gpg-metadata)
  - [Multi-architecture images](#multi-architecture-images)
  - [Help wanted!](#help-wanted)

<!-- /TOC -->

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
          - /vault-agent-auto-inject-webhook
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
`-mount-ca-cert-secret` | Indicate if the Secret indicated by the -ca-cert-secret-name flag should be mounted on the Vault agent container | `false`
`-ca-cert-secret-name` | The name of the secret in the target namespace to mount and use as a CA cert | `vault-tls`
`-cpu-request` | The amount of CPU units to request for the Vault agent sidecar") | `50m`
`-cpu-limit` | The amount of CPU units to limit to on the Vault agent sidecar") | `100m`
`-memory-request` | The amount of memory units to request for the Vault agent sidecar") | `128Mi`
`-memory-limit` | The amount of memory units to limit to on the Vault agent sidecar") | `256Mi`
`-listen-addr` | The address to start the server | `:4443`
`-metrics-addr` | The address where the Prometheus-style metrics are published | `:8081`

### ConfigMap

The webhook expects that a `ConfigMap` named `vault-agent-config` (or something else, if the `-default-config-map-name` was passed to the server) will exist in the same namespace as the target Pod (**NOT** in the same namespace as the webhook itself), that will contain only one key, called `vault-agent-config.hcl`, which will contain a [Go template](https://golang.org/pkg/text/template/) that will be rendered into the Vault agent configuration using [`gomplate`](https://github.com/hairyhenderson/gomplate), and will have the following environment variables available to be discovered with the `getenv` function:

Environment variable | Value
---------------------|------
`SERVICE` | The name of the `ServiceAccount` attached to the pod
`TARGET_VAULT_ADDRESS` | The value of the `-target-vault-address` parameter (or its default)
`KUBERNETES_AUTH_PATH` | The value of the `-kubernetes-auth-path` parameter (or its default)

### Auto-mount CA cert

If enabled with the `-mount-ca-cert-secret` flag, the webhook can automatically create a volume from the secret indicated by the `-ca-cert-secret-name` flag. The volume will then be mounted at `/opt/vault/certs/` on the Vault agent container **only**, so the `vault-agent-config.hcl` file can use the [`ca_cert` field](https://www.vaultproject.io/docs/agent/index.html#inlinecode-ca_cert-string-optional-1) in the `vault` stanza, instead of skipping verification with `tls_skip_verify = true`.

### Init containers

Alternatively, the webhook can inject the Vault agent as an init container instead of a sidecar, which is useful for short-lived workloads, like `Job`s and `CronJob`s. In that case, the init container should use a configuration that has `exit_after_auth = true` so the init container exists after authenticating and doesn't remain long-lived. Doing so, would cause the container to never exit past the init container phase. The config file should also contain at least one [file sink](https://www.vaultproject.io/docs/agent/autoauth/sinks/file.html). The webhook will also modify the containers to mount an additional volume on `/vault-agent` that can be used as a file sink.

To do this, annotate your workload with `vault.patoarvizu.dev/agent-auto-inject: init-container`.

Usually, a given config file will only be suitable for either long-lived sidecars or short-lived init containers. If the default config map (`vault-agent-config` by default, or the overwrite if `-default-config-map-name` was provided) is not suitable for a specific application, it can be overwritten with the `vault.patoarvizu.dev/agent-config-map` annotation. If set, the value should be the name of a `ConfigMap` in the same namespace that that the webhook should use to inject, instead of the default one.

### Metrics

The webhook will also expose Prometheus-style metrics on port HTTP/8081 (unless overwritten with `-metrics-addr`), ready to be scraped. The metrics are provided by the underlying [slok/kubewebhook](https://github.com/slok/kubewebhook) framework and include `admission_reviews_total`, `admission_review_errors_total`, and `admission_review_duration_seconds`.

### Auto-reloading certificate

The server performs a hot reload if the underlying TLS certificate (indicated by the `-tls-cert-file` flag) on disk is modified. This is helpful when using automatic certificate provisioners like cert-manager that will do automatic rotation of the certificates but can't control the lifecycle of the workloads using the certificate.

The way this is achieved is by initially loading the certificate and keeping it in a local cache, then using the [radovskyb/watcher](https://github.com/radovskyb/watcher) library to watch for changes on the file and updating the cached version if the file changes.

## For security nerds

### Docker images are signed and published to Docker Hub's Notary server

The [Notary](https://github.com/theupdateframework/notary) project is a CNCF incubating project that aims to provide trust and security to software distribution. Docker Hub runs a Notary server at https://notary.docker.io for the repositories it hosts.

[Docker Content Trust](https://docs.docker.com/engine/security/trust/content_trust/) is the mechanism used to verify digital signatures and enforce security by adding a validating layer.

You can inspect the signed tags for this project by doing `docker trust inspect --pretty docker.io/patoarvizu/vault-agent-auto-inject-webhook`, or (if you already have `notary` installed) `notary -d ~/.docker/trust/ -s https://notary.docker.io list docker.io/patoarvizu/vault-agent-auto-inject-webhook`.

If you run `docker pull` with `DOCKER_CONTENT_TRUST=1`, the Docker client will only pull images that come from registries that have a Notary server attached (like Docker Hub).

### Docker images are labeled with Git and GPG metadata

In addition to the digital validation done by Docker on the image itself, you can do your own human validation by making sure the image's content matches the Git commit information (including tags if there are any) and that the GPG signature on the commit matches the key on the commit on github.com.

For example, if you run `docker pull patoarvizu/vault-agent-auto-inject-webhook:c1201e30e90d9d8fd2f2f65f2552236013cdcbe8` to pull the image tagged with that commit id, then run `docker inspect patoarvizu/vault-agent-auto-inject-webhook:c1201e30e90d9d8fd2f2f65f2552236013cdcbe8 | jq -r '.[0].ContainerConfig.Labels'` (assuming you have [jq](https://stedolan.github.io/jq/) installed) you should see that the `GIT_COMMIT` label matches the tag on the image. Furthermore, if you go to https://github.com/patoarvizu/vault-agent-auto-inject-webhook/commit/c1201e30e90d9d8fd2f2f65f2552236013cdcbe8 (notice the matching commit id), and click on the **Verified** button, you should be able to confirm that the GPG key ID used to match this commit matches the value of the `SIGNATURE_KEY` label, and that the key belongs to the `AUTHOR_EMAIL` label. When an image belongs to a commit that was tagged, it'll also include a `GIT_TAG` label, to further validate that the image matches the content.

Keep in mind that this isn't tamper-proof. A malicious actor with access to publish images can create one with malicious content but with values for the labels matching those of a valid commit id. However, when combined with Docker Content Trust, the certainty of using a legitimate image is increased because the chances of a bad actor having both the credentials for publishing images, as well as Notary signing credentials are significantly lower and even in that scenario, compromised signing keys can be revoked or rotated.

Here's the list of included Docker labels:

- `AUTHOR_EMAIL`
- `COMMIT_TIMESTAMP`
- `GIT_COMMIT`
- `GIT_TAG`
- `SIGNATURE_KEY`

## Multi-architecture images

Manifests published with the semver tag (e.g. `patoarvizu/vault-agent-auto-inject-webhook:v0.5.0`), as well as `latest` are multi-architecture manifest lists. In addition to those, there are architecture-specific tags that correspond to an image manifest directly, tagged with the corresponding architecture as a suffix, e.g. `v0.15.0-amd64`. Both types (image manifests or manifest lists) are signed with Notary as described above.

Here's the list of architectures the images are being built for, and their corresponding suffixes for images:

- `linux/amd64`, `-amd64`
- `linux/arm64`, `-arm64`
- `linux/arm/v7`, `arm7`

## Help wanted!

All Issues or PRs on this repo are welcome, even if it's for a typo or an open-ended question.