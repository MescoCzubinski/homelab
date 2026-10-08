# Infra

- [x] Traefik — ingress for everything
- [x] VPN-only middleware — HTTP and TCP
- [x] TLS — ACME wildcard for \*.czubinski.dev
- [x] Cloudflared — public entrypoint without open ports
- [x] GitHub-only middleware
- [x] Argo CD
- [x] Declarative infra — Argo CD manages itself and infra
- [x] Namespace per app
- [x] Sealed Secrets — no more .env files
- [x] Application per component — applications dir
- [x] Argo CD webhook — sync on push
- [x] Pin image versions everywhere
- [x] Resource limits per app
- [x] Helm chart for apps
- [x] Argo CD Image Updater
- [x] One Application per tool
- [x] Generic app chart — reconsider vs per-app manifests
- [ ] Helm charts for tools — use upstream charts where they exist
- [x] Sync waves — Namespace → Secret → Chart, not everything at once
- [x] Readiness probes — no traffic to pods that aren't up yet during rollouts
- [ ] Renovate — tracking pinned versions outside image updater
- [ ] Dedicated VIP and DNS for API server instead of node IPs in k0s sans - k8s.czubinski.dev
- [ ] Uptime Kuma — tells me when something is down
- [ ] Postgres — shared database for apps that need one,
- [ ] Mongodb — shared database for apps that need one,

## Apps

- [x] Syncthing
- [x] Beszel
- [x] Samba
- [x] ConvertX
- [x] Stirling PDF
- [x] Homepage
- [x] Meetly
- [ ] RustDesk
- [ ] Sonarr, Radarr, Lidarr
- [ ] AFFiNE — needs Postgres
