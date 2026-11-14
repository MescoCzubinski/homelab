# Review instructions

Same rules as `.coderabbit.yaml`. A change to one goes into the other.

Be concise and direct. No pleasantries, only concrete, actionable comments.

## What Important means here

Anything that breaks a Security rule below is Important.

## Cap the nits

Report at most five Nits per review.

## Do not report

- `sealed-secret.yaml` and `*-sealed-secret.yaml`: SealedSecret ciphertext
- `*.pem` files
- `.docs/images/`: diagrams that can't be edited in a PR

## Always check

### `tools/`, `infra/`, `apps/`, `charts/`

Security: flag anything that grows the attack surface or blast radius.

- Ingress names its entrypoint. HTTP VPN-only: entrypoint `websecure`, middleware `default-http-vpn-only@kubernetescrd`. TCP: the entrypoint configured in `infra/traefik/values.yaml`, middleware `tcp-vpn-only` from `default`. `public` only for public apps.
- Pods: runAsNonRoot, no privilege escalation, drop ALL, seccomp RuntimeDefault, read-only root fs where possible, no ServiceAccount token unless the pod has its own ServiceAccount, requests and limits.
- hostNetwork, hostPID, hostIPC, hostPath outside `/home/server/`, hostPort, privileged or extra capabilities need a reason, as a PolicyException in `.github/policies/pod-security.yaml`.
- Secrets only as SealedSecrets, never in values.yaml, env or plain Secrets.
- Images and charts pinned, never `latest`.
- NetworkPolicies no wider (sources, destinations, ports) than needed.

Consistency: same kind of component, same shape.

- Every namespace: default-deny NetworkPolicies plus explicit allows, named `<source>-to-<target>` (a namespace, `nobody`, `vpn` or `apiserver`, e.g. `traefik-to-gatus`, `atlas-to-dns`, `apiserver-to-cnpg`). Ingress in the target's namespace, egress in the source's.
- Pod Security labels via managedNamespaceMetadata: apps `enforce: restricted`, tools `warn`/`audit: restricted`, infra `warn`/`audit: baseline`.
- New tool, like its peers: `networkpolicy.yaml` with `traefik-to-<tool>` and `gatus-to-<tool>`, a check in `tools/gatus/values.yaml`, an Application in `infra/argocd/applications/` with the resources finalizer, prune, selfHeal and `CreateNamespace=true`.
- Own apps via `charts/app` (`apps/<app>/values.yaml`), the Application pins a published chart version.
- Upstream charts over hand-written manifests where possible, values in this repo (`$values`).
- Reuse existing patterns instead of adding new ones.

### `charts/app/`

Every change bumps the version in `Chart.yaml` and must work with the values of atlas, homepage and meetly.

### `.docs/`

README, `.docs` and TODO must match the code changes in the PR.
