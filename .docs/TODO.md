# Infra

- [ ] Resource limits per app — one pod shouldn't be able to starve the node
- [ ] Helm charts — versioned releases; Image Updater needs Helm or Kustomize
- [ ] Argo CD Image Updater — a new tag deploys itself, no manual manifest edits
- [ ] Postgres — shared database for apps that need one, with backups
- [ ] Readiness probes — no traffic to pods that aren't up yet during rollouts
- [ ] Uptime Kuma — tells me when something is down

## Apps

- [ ] RustDesk
- [ ] Sonarr, Radarr, Lidarr
- [ ] AFFiNE — needs Postgres
