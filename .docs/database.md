# Database

## Overview

Every app that needs a database gets its own PostgreSQL 17 cluster in its own namespace, run by CloudNativePG.

- **Operator:** `cnpg` Application, upstream chart in namespace `cnpg-system`
- **Cluster:** `postgres: true` in an app's `values.yaml` makes `charts/app` create a `Cluster` `<app>-pg` in the app's namespace, one instance, no replicas
- **Database:** `<app>`, owned by the role `<app>`
- **Superuser:** disabled (`enableSuperuserAccess: false`)
- **Credentials:** CNPG generates the secret `<app>-pg-app` (`username`, `password`, `uri`, ...). The app reads it through `secretEnv` with a `secret/key` value, e.g. `DATABASE_URL: atlas-pg-app/uri`, so there is no sealed secret for the database.
- **Sync wave:** an Application with `postgres: true` is at wave `1`, so it syncs after the `cnpg` operator (default wave) and its CRDs

## Storage

One static `local` PersistentVolume per app ([persistentvolumes.yaml](../infra/cnpg/persistentvolumes.yaml)) on the host, 10 Gi, `Retain`:

- **Path:** `/home/server/postgres/<app>`, created by hand before the first sync
- **Reserved for one app:** `claimRef` names the only claim allowed to use the PV, `<app>/<app>-pg-1`
- **Tied to the node:** the data is a folder on this server's disk, so `nodeAffinity` pins the PV to the node `myserver.home` (`kubernetes.io/hostname`)
- **StorageClass:** `local-postgres` links the database's PVC to these PVs. It has no provisioner, so Kubernetes never creates volumes itself and only uses the PVs defined by hand

## Access

NetworkPolicies from `charts/app` for the `<app>-pg` pods, only when `postgres: true`:

| policy               | allows                                                      |
| -------------------- | ----------------------------------------------------------- |
| `cnpg-to-<app>`      | `cnpg-system` to the database on `5432` and `8000` (status) |
| `<app>-to-<app>`     | the app's own pods to the database on `5432`                |
| `<app>-to-apiserver` | the database to the API server (`192.168.1.100:6443`)       |

The database pods are left out of `traefik-to-<app>` and `<app>-to-internet`, so only the app's pods (on `5432`) and `cnpg-system` reach them, and they reach only DNS (`<app>-to-dns`) and the API server.
