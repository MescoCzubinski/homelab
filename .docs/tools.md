# Tools

Self-hosted tools, each synced by its own Argo CD Application, either as plain manifests or an upstream Helm chart. All are VPN-only and reachable only through Traefik, and their data lives in `hostPath` under `/home/server/`

![Tools](images/tools.png)

Dashed `svc` boxes are config only: Traefik reads pod IPs from them and connects to pods directly.

## Addresses and data

- **Beszel:** server monitoring at `beszel.czubinski.dev`, data in `/home/server/beszel/hub-data`
- **ConvertX:** file conversion at `convert.czubinski.dev`, data in `/home/server/convertx/data`
- **Gatus:** uptime checks and status page at `gatus.czubinski.dev`, data in `/home/server/gatus/data` (SQLite)
- **Stirling PDF:** PDF tools at `stirling.czubinski.dev`, data in `/home/server/stirling/config`
- **Syncthing:** file sync at `syncthing.czubinski.dev` and `:22000`, data in `/home/server/syncthing/{config,data}`
- **Samba:** network share `Shared` at `\\192.168.0.1\Shared` (`:445`), data in `/home/server/samba/Shared`
