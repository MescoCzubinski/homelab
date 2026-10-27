# Commits

`v{version}` appears only when the commit changes a version, so `git log --grep "^traefik v"` is the version history of Traefik.

| Commit                     | Format                         | Example                                |
| -------------------------- | ------------------------------ | -------------------------------------- |
| Bump (Renovate or by hand) | `{name} v{version}`            | `traefik v42.0.0`                      |
| Update, no bump            | `{name}: {changes}`            | `gatus: networkpolicies`               |
| Update and bump            | `{name} v{version}: {changes}` | `cloudflared v2026.10.3: read-only fs` |
| Init                       | `{name} v{version}: init`      | `gatus v1.5.0: init`                   |
| Init, own app              | `{name} v0.0.1: init`          | `atlas v0.0.1: init`                   |
| Init, no version           | `{name}: init`                 | `namespaces: init`                     |
| Change to several tools    | `tools: {changes}`             | `tools: recreate strategy`             |
| CI, Renovate, CodeRabbit   | `ci: {changes}`                | `ci: renovate commit format`           |
| Docs                       | `docs: {changes}`              | `docs: commit conventions`             |
| Things without a version   | `{name}: {changes}`            | `kubelet: worker profile`              |

`{name}` is the app or directory (`traefik`, `gatus`). Renovate follows the same format through `commitMessageTopic` and `commitMessageExtra` in `renovate.json`, with a `packageRules` entry where the chart or image name differs from `{name}` (`argo-cd`, `cloudnative-pg`, `stirling-pdf`). Argo CD Image Updater writes back to the Application in the cluster, not to git, so it makes no commits.

- **Init:** `{version}` is the version the app starts with. If it started on `latest`, it is the first version tracked in the repo. Own apps (atlas, homepage, meetly) always start at `v0.0.1`. Plain resources without a version use `{name}: init`.
- **Tools:** `tools:` is for a change to the `tools/` directory as a whole (several tools at once, sometimes cloudflared). A change to one tool uses that tool's name.
- **Helm:** for an app installed from a Helm chart, `{version}` is the chart version (`targetRevision`), the one Renovate bumps. Stirling also pins its image in `values.yaml` and Renovate bumps both, so `stirling v{version}` is the image version and a chart bump is `stirling: helm chart {version}`, which `--grep "^stirling v"` skips.
