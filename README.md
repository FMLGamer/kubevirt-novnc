# kubevirt-novnc

Web UI for viewing KubeVirt virtual machines, opening noVNC consoles, and sending start/stop/restart actions through the Kubernetes API proxy.

## What This Project Provides

- A static noVNC-based frontend served by `kubectl proxy`
- VM table with phase, readiness, age, and console access
- VM lifecycle actions: start, stop, restart
- Traefik IngressRoute example with HTTP Basic Auth
- Cluster-internal Service (`ClusterIP`) for safer exposure via ingress

## Architecture

- Container image is built from `bitnami/kubectl:1.29.0`
- Static web assets are copied to `/static`
- Entrypoint runs:

```bash
kubectl proxy --www=/static --accept-hosts=^.*$ --address=[::] --api-prefix=/k8s/ --www-prefix=
```

This means the browser UI is static content, and all API calls are made via the proxy path `/k8s/...`.

## Prerequisites

- Kubernetes cluster with KubeVirt installed
- Traefik installed (for the provided ingress example)
- A namespace containing your target KubeVirt VMs
- Permissions that allow listing VMs and accessing KubeVirt subresources

## Quick Deploy (Manifest Included)

Use the provided manifest in [k8s/kv-novnc.yaml](k8s/kv-novnc.yaml).

1. Review and edit defaults before applying:

```bash
kubectl apply --dry-run=client -f k8s/kv-novnc.yaml
```

2. Update these values in [k8s/kv-novnc.yaml](k8s/kv-novnc.yaml):

- Basic auth secret in namespace `traefik`:
  - `data.username` (base64)
  - `data.password` (base64)
- Traefik route host:
  - `spec.routes[0].match` in `IngressRoute`

3. Apply:

```bash
kubectl apply -f k8s/kv-novnc.yaml
```

4. Open the configured hostname over HTTPS.

## Important Configuration Notes

- The UI currently uses a fixed namespace in [static/index.html](static/index.html):
  - `const namespace = 'virtual-azurion';`
- The previously documented `?namespace=` query parameter is not used by the current code.
- If your VMs are in a different namespace, change that constant and rebuild/redeploy the image.

## Build And Publish

Build locally:

```bash
docker build -t kubevirt-novnc:local .
```

If you publish to a registry, update the Deployment image in [k8s/kv-novnc.yaml](k8s/kv-novnc.yaml) accordingly.

## Release Process (GitHub)

1. Create and push a semantic version tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

2. In GitHub, open **Releases** -> **Draft a new release**.
3. Select the tag and use [.github/RELEASE_TEMPLATE.md](.github/RELEASE_TEMPLATE.md) as the release body.
4. Enable auto-generated release notes (optional but recommended). Categories are configured in [.github/release.yml](.github/release.yml).
5. Publish and then update manifests/consumers to the newly released image tag.

## Suggested GitHub Release Practices

- Protect `main` with required PR reviews and status checks.
- Use conventional labels (`breaking`, `feature`, `bug`, `docs`, `security`) so release notes are categorized automatically.
- Keep release tags immutable (`vX.Y.Z`) and avoid retagging after publish.
- Attach rollout notes and rollback notes in each release body.
- Include compatibility notes (Kubernetes and KubeVirt versions tested).
- Optionally sign container images and generate SBOM/provenance for supply-chain traceability.

## Helm: Pin Version In values.yaml (bitnami/nginx)

When deploying `bitnami/nginx`, pin by immutable image tag or digest in your Helm values:

```yaml
image:
  registry: docker.io
  repository: bitnami/nginx
  # Prefer a fixed, non-latest tag
  tag: 1.27.1-debian-12-r3
  pullPolicy: IfNotPresent

  # Stronger pinning: use digest (if chart version supports digest field)
  # digest: "sha256:0123456789abcdef..."
```

Install/upgrade with pinned values:

```bash
helm upgrade --install web bitnami/nginx -f values.yaml
```

If your chart supports both `tag` and `digest`, prefer digest because it is immutable.

## Security Notes

- Basic auth is handled by Traefik middleware in the `traefik` namespace.
- Service type is `ClusterIP`, so access is intended through ingress.
- RBAC is cluster-scoped in the provided manifest. Review and tighten to your environment if needed.

## Lineage

This repository was forked from [wavezhang/virtVNC](https://github.com/wavezhang/virtVNC) (commit [0fe6d5a](https://github.com/wavezhang/virtVNC/commit/0fe6d5a1ffdf9aed88dbd507f7b43a4cac5d343d)) and has been customized for this deployment model.

## License

MIT. See [LICENSE.md](LICENSE.md).
