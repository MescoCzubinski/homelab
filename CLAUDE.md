# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

GitOps repo for a single-node k0s cluster on a Mac Mini (node `myserver.home`, LAN IP `192.168.1.100`, VPN IP `192.168.0.1`). Argo CD applies everything in `infra/`, `apps/` and `tools/` from `main`. Nothing gets `kubectl apply`'d by hand, and `selfHeal` reverts manual changes. The README and `.docs/` explain the design. Read the relevant doc before you change a subsystem.

## Commands

No build. CI (`.github/workflows/validate.yaml`) renders every Helm-based Application and validates the output with kubeconform. It fails if `charts/app` differs from the chart published on GHCR under the same version. `.github/workflows/trivy.yaml` scans upstream images every Monday and fails on a CRITICAL CVE that has a fix (`apps/` images are skipped, their tags aren't in git). `.github/workflows/gitleaks.yaml` scans the git history on every push to `main`, `.gitleaks.toml` allows SealedSecret ciphertext. To check locally:

```sh
# charts/app with one app's values (repeat for atlas, homepage, meetly)
helm lint charts/app -n atlas -f apps/atlas/values.yaml
helm template atlas charts/app -n atlas -f apps/atlas/values.yaml

# plain manifests (CI uses Kubernetes 1.36.2)
kubeconform -strict -summary -ignore-missing-schemas -kubernetes-version 1.36.2 -skip SealedSecret \
  -ignore-filename-pattern 'values.yaml' -ignore-filename-pattern 'k0sctl.yaml' tools infra
```

Seal a secret with `scripts/create-secret.sh`, on `PATH` through `flake.nix` (direnv or `nix develop`). It creates or updates the namespace's `sealed-secret.yaml`. Leave out `value` for a hidden prompt, so the plaintext stays out of shell history. A new file deploys only if its Application's `directory.include` lists it.

```sh
create-secret.sh <namespace> <name> [key] [value]
```

## Architecture

**App of apps.** The `argocd` Application (`infra/argocd/applications/argocd.yaml`) deploys Argo CD itself, the files in `infra/argocd/` and one child Application per file in `infra/argocd/applications/`. A Helm-based Application has up to three sources: the chart (upstream, or `charts/app` from GHCR) with `valueFiles: $values/...`, this repo as `ref: values`, and this repo again with `path` + `directory.include` for extra manifests (sealed secrets, NetworkPolicies, ingresses). A plain-manifest Application has a single `source.path`.

**Three tiers, each with its own shape:**

| tier     | how it's deployed                                                                 | access                         | Pod Security labels                  |
| -------- | --------------------------------------------------------------------------------- | ------------------------------ | ------------------------------------ |
| `apps/`  | `values.yaml` for the shared `charts/app` chart, Application pins a chart version | `public` via Cloudflare tunnel | `enforce`/`warn`/`audit: restricted` |
| `tools/` | upstream chart + `values.yaml` where one exists, else plain manifests             | VPN only                       | `warn`/`audit: restricted`           |
| `infra/` | upstream chart or plain manifests                                                 | n/a                            | `warn`/`audit: baseline`             |

The labels are set through the Application's `managedNamespaceMetadata`. Tools keep data in `hostPath` under `/home/server/<tool>/`, use `strategy: Recreate` and `revisionHistoryLimit: 3`.

**`charts/app`.** A list of `components`, each rendered as a Deployment + Service. The Ingress routes each component's `paths` on `host` (default `<release>.czubinski.dev`). `access` (`public`/`vpn`/`github`) picks the Traefik entrypoint and middleware. `values.schema.json` has `additionalProperties: false`, so a new value needs a schema entry. `secretEnv` maps `ENV: secret` or `ENV: secret/key`. The chart also ships the app's NetworkPolicies, so app policies are changed here, not in `apps/`.

**Traffic.** Public: Cloudflare → `cloudflared` → Traefik entrypoint `public`. Private: WireGuard → Traefik `websecure` (HTTP, middleware `default-http-vpn-only@kubernetescrd`) or a TCP entrypoint from `infra/traefik/values.yaml` (`IngressRouteTCP` with middleware `tcp-vpn-only` from namespace `default`). The Argo CD webhook is the one `public` route with a middleware (`http-gh-only`, GitHub IP ranges only). Details: `.docs/network.md`.

**NetworkPolicies.** Every namespace is default-deny, plus one policy per allowed path, named `<source>-to-<target>` (`traefik-to-gatus`, `atlas-to-dns`, `nobody-to-<ns>` is the deny). Ingress policies live in the target's namespace, egress policies in the source's. Public apps also get egress limits: DNS, own namespace and the internet, but not RFC1918 ranges.

**Updates.** Two separate paths, which must not overlap:

- `apps/`: Argo CD Image Updater moves image tags to the newest `vX.Y.Z` on GHCR and writes them to the Application as `helm.parameters`, not to git. `tag: v0.0.1` in `values.yaml` is only a baseline, and Renovate is disabled for `apps/**`.
- Everything else: Renovate PRs (majors any time, minors and action digests on the 1st of the month, patches only for `argo-cd`, `traefik` and `cloudflared`, 3-day minimum release age). `renovate.json` rewrites commit messages to follow the commit conventions below. If a new package's name doesn't match its directory/Application name, add a `commitMessageTopic` packageRule.

**Postgres.** `postgres: true` in an app's values creates a CNPG `Cluster` `<app>-pg` (credentials in the generated `<app>-pg-app` secret, used via `secretEnv`) and its NetworkPolicies. It also needs a static PV in `infra/cnpg/persistentvolumes.yaml` (`claimRef` `<app>/<app>-pg-1`, path `/home/server/postgres/<app>` created by hand on the host) and `sync-wave: "1"` on the Application. Details: `.docs/database.md`.

**Sync waves.** SealedSecrets `-1`, default `0` (operators such as `cnpg`), Applications with `postgres: true` `1`.

## Rules

### Consistency

Components of the same kind have the same shape. Before you add or change something, look at its peers (the other tools, the other Applications, the other NetworkPolicies) and copy their structure, field order and naming. Add a new pattern only when no existing one fits.

When you change something in one file and the same improvement applies to its peers, apply it to all of them in the same change. The commit history does this too: `tools: recreate strategy`, `tools: non-root, read-only fs, drop ALL`. If you skip a peer on purpose, say why.

A new tool comes with all of these:

- an Application in `infra/argocd/applications/` with `prune`, `selfHeal`, `CreateNamespace=true` and the tool-tier PSA labels
- `networkpolicy.yaml` with `traefik-to-<tool>` and `gatus-to-<tool>`
- a check in `tools/gatus/values.yaml`
- Renovate coverage (an image under `tools/` is picked up automatically, a chart in its Application too)
- the docs listed under [Docs](#docs)

A `charts/app` change bumps `Chart.yaml` `version` and must render with the values of atlas, homepage and meetly.

### Security

Make every change as secure as the component allows, especially in `tools/`. Flag anything that grows the attack surface or blast radius:

- Ingress always names its entrypoint. `public` only for public apps, everything else VPN-only through the middlewares above.
- Pods: `runAsNonRoot`, `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`, `seccompProfile: RuntimeDefault`, `readOnlyRootFilesystem: true` with `emptyDir` for writable paths where the image allows it, requests and limits.
- `hostNetwork`, `hostPath` outside `/home/server/`, `hostPort`, `privileged` or added capabilities need a stated reason (current ones: beszel agent `hostNetwork`, samba running as root with added capabilities, Traefik `hostPort`s).
- Secrets only as SealedSecrets, never in `values.yaml`, `env` or plain Secrets.
- Images and charts pinned to a version, never `latest`.
- NetworkPolicies no wider (sources, destinations, ports) than needed.
- Never decode or print secret values from the cluster, not even partially. Debug with metadata, SealedSecret status/events and logs, and ask the user to check a value themselves.

### Docs

After any change, check whether `README.md`, `.docs/*.md` or `.docs/TODO.md` describe what you changed, and update them in the same change. Keep their terse style.

- README body links only to `.docs/` documents. Repo paths go in backticks, no external links. The Services section is the exception: public apps link to their live URL, tools to their project page.
- `.docs/images/*.png` are diagrams that can't be edited here. If a change makes one outdated, tell the user.

### Commits

Messages are lowercase, with no trailing period. `{name}` is the app or directory (`traefik`, `gatus`).

- **Bump** (Renovate or by hand): `{name} v{version}`, e.g. `traefik v42.0.0`
- **Update, no bump:** `{name}: {changes}`, e.g. `gatus: networkpolicies`. No `v{version}`, because the commit changes no version. Also used for things without a version, e.g. `kubelet: worker profile`
- **Update and bump:** `{name} v{version}: {changes}`, e.g. `cloudflared v2026.10.3: read-only fs`
- **Init:** `{name} v{version}: init`, e.g. `gatus v1.5.0: init`. `{version}` is the version the app starts with, or the first version tracked in the repo if it started on `latest`
- **Init, own app:** `{name} v0.0.1: init`, e.g. `atlas v0.0.1: init`. Own apps (atlas, homepage, meetly) always start at `v0.0.1`
- **Init, no version:** `{name}: init`, e.g. `namespaces: init`. For plain resources without a version
- **Several tools:** `tools: {changes}`, e.g. `tools: recreate strategy`. For a change to the `tools/` directory as a whole (sometimes cloudflared). A change to one tool uses that tool's name
- **CI, Renovate, CodeRabbit:** `ci: {changes}`, e.g. `ci: renovate commit format`
- **Docs:** `docs: {changes}`, e.g. `docs: commit conventions`

`charts/app` commits use `helm` as `{name}`, e.g. `helm v0.2.0: postgres per app`.
