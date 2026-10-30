# Homelab

Single-node Kubernetes homelab on a Mac Mini, run with k0s and managed by Argo CD in GitOps style. Public apps are reached through a Cloudflare Tunnel with no open ports, while private tools sit behind a VPN.

![Network](.docs/images/full.png)

## Stack

- **Hardware:** Mac Mini 2012, i7-3720QM, 16 GB RAM, 250 GB SSD ([hardware.md](.docs/hardware.md))
- **Kubernetes:** k0s, config in `cluster/k0sctl.yaml`
- **GitOps:** Argo CD ([argocd.md](.docs/argocd.md))
- **Ingress:** Traefik, config in `infra/traefik/values.yaml`
- **Public access:** Cloudflare Tunnel (`cloudflared`)
- **Database:** CloudNativePG ([database.md](.docs/database.md))
- **Secrets:** Sealed Secrets
- **Updates:** Renovate and Argo CD Image Updater ([argocd.md](.docs/argocd.md))

## File structure

```
.docs/                   docs and diagrams
.github/                 CI workflows
apps/                    public apps
  atlas/
  homepage/
  meetly/
charts/
  app/                   Helm chart for apps
cluster/                 k0s config
infra/
  argocd/                Argo CD, Applications
  argocd-image-updater/  Image Updater
  cloudflared/           Cloudflare Tunnel
  cnpg/                  CloudNativePG, database storage
  kube-vip/              API server VIP
  sealed-secrets/        Sealed Secrets
  traefik/               Traefik, middlewares
tools/                   private tools
  beszel/
  convertx/
  gatus/
  samba/
  stirling/
  syncthing/
```

Each public app in `apps/` is a `values.yaml` for the shared `charts/app` Helm chart, plus `sealed-secret.yaml` if needed. Apps pin a chart version, published to GHCR when a `vX.Y.Z` tag matching `charts/app/Chart.yaml` is pushed.

Each private tool in `tools/` has its own Application: a plain directory of manifests, or a `values.yaml` for an upstream chart where one exists.

## Services

### Public

- [homepage](https://czubinski.dev) - my personal webpage
- [atlas](https://atlas.czubinski.dev)
- [meetly](https://meetly.czubinski.dev) - a web app that helps people in one room find each other

### Private

- [Argo CD](https://argoproj.github.io/cd/) - GitOps controller
- [Beszel](https://beszel.dev) - server monitoring
- [ConvertX](https://github.com/C4illin/ConvertX) - file converter
- [Gatus](https://gatus.io) - status page and health checks
- [Stirling PDF](https://www.stirling.com) - PDF tools
- [Syncthing](https://syncthing.net) - file sync
- [Samba](https://www.samba.org) - network file share

Tool details and where their data lives: [.docs/tools.md](.docs/tools.md).

## Networking

- **Public:** `*.czubinski.dev` goes through Cloudflare and the `cloudflared` tunnel to Traefik's `public` entrypoint. No ports are opened on the router.
- **VPN:** WireGuard via `vpn.czubinski.dev` (DynDNS). Connected devices reach Traefik's private entrypoints on `192.168.0.1`.

Diagrams, firewall, Traefik entrypoints and networking details in: [.docs/network.md](.docs/network.md).
