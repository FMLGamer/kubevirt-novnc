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

## Security Notes

- Basic auth is handled by Traefik middleware in the `traefik` namespace.
- Service type is `ClusterIP`, so access is intended through ingress.
- RBAC is cluster-scoped in the provided manifest. Review and tighten to your environment if needed.

## Lineage

This repository was forked from [wavezhang/virtVNC](https://github.com/wavezhang/virtVNC) (commit [0fe6d5a](https://github.com/wavezhang/virtVNC/commit/0fe6d5a1ffdf9aed88dbd507f7b43a4cac5d343d)) and has been customized for this deployment model.

## License

MIT. See [LICENSE.md](LICENSE.md).
