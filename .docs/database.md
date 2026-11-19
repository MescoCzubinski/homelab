# Database

## Overview

Every app that needs a database gets its own, in its own namespace, switched on in the app's `values.yaml`: `postgres: true` for PostgreSQL ([Postgres](#postgres)), `duckdb.image` for DuckDB ([DuckDB](#duckdb)). Nothing is shared between apps.

- **Created by:** `charts/app`, from the app's `values.yaml`
- **Resources:** none on the database pods, and the chart sets no defaults. The app's own components and jobs have theirs in `values.yaml`

## Storage

One static `local` PersistentVolume per app and database on the host, 10 Gi, `Retain`, so the data survives restarts, redeploys and removing the app:

- **Path:** `/home/server/<postgres|duckdb>/<app>`, created by hand before the first sync
- **Reserved for one app:** `claimRef` names the only claim allowed to use the PV
- **Tied to the node:** the data is a folder on this server's disk, so `nodeAffinity` pins the PV to the node `myserver.home` (`kubernetes.io/hostname`)
- **StorageClass:** `local-postgres` or `local-duckdb` links the database's PVC to these PVs. They have no provisioner, so Kubernetes never creates volumes itself and only uses the PVs defined by hand

## Access

NetworkPolicies from `charts/app` let in only the app's own pods, on the database's port. The database pods are left out of `traefik-to-<app>` and `<app>-to-internet`, so nothing else reaches them and they reach only DNS (`<app>-to-dns`), plus what each database lists below.

## Postgres

Every app that needs PostgreSQL gets its own PostgreSQL 17 cluster, run by CloudNativePG.

- **Operator:** `cnpg` Application, upstream chart in namespace `cnpg-system`
- **Cluster:** `postgres: true` makes `charts/app` create a `Cluster` `<app>-pg` in the app's namespace, one instance, no replicas
- **Database:** `<app>`, owned by the role `<app>`
- **Superuser:** disabled (`enableSuperuserAccess: false`)
- **Credentials:** CNPG generates the secret `<app>-pg-app` (`username`, `password`, `uri`, ...). The app reads it through `secretEnv` with a `secret/key` value, e.g. `DATABASE_URL: atlas-pg-app/uri`, so there is no sealed secret for the database.
- **Sync wave:** an Application with `postgres: true` is at wave `1`, so it syncs after the `cnpg` operator (default wave) and its CRDs
- **Storage:** PVs in [persistentvolumes.yaml](../infra/cnpg/persistentvolumes.yaml), `claimRef` `<app>/<app>-pg-1`, StorageClass `local-postgres`
- **Access:**

| policy               | allows                                                      |
| -------------------- | ----------------------------------------------------------- |
| `cnpg-to-<app>`      | `cnpg-system` to the database on `5432` and `8000` (status) |
| `<app>-to-<app>`     | the app's own pods to the database on `5432`                |
| `<app>-to-apiserver` | the database to the API server (`192.168.1.101:6443`)       |

## DuckDB

An app that needs an analytics warehouse gets its own DuckDB file, served over Quack in the app's namespace.

- **Server:** `duckdb.image` makes `charts/app` run `<app>-duckdb` from that image, behind a Service on `duckdb.port` (Quack's default is `9494`). Every component and job of the app gets it as `QUACK_PORT`
- **Image:** built by the app's own repo, with no app code. It runs as uid `1000`, reads `QUACK_PORT` and `QUACK_TOKEN`, keeps its file in `/data` and has `quack` and `httpfs` installed at build time, because the server has no internet. It is tagged with the app's `vX.Y.Z`, but built only on releases that change the server, so the app's images can be ahead of it. Image Updater moves `duckdb.image.tag` to the newest one, like the app's images
- **Single writer:** DuckDB locks its file, so the Deployment uses `strategy: Recreate`
- **Token:** the SealedSecret `<app>-duckdb`, key `token`. The server reads it as `QUACK_TOKEN`, the app's clients through `secretEnv`, e.g. `QUACK_TOKEN: <app>-duckdb/token`
- **Storage:** the file lives in `/data`, on the PVC `<app>-duckdb`. PVs in `infra/duckdb/` (`duckdb` Application), `claimRef` `<app>/<app>-duckdb`, StorageClass `local-duckdb`, directory owned by uid `1000`, the image's user
- **Access:** `<app>-to-<app>-duckdb` lets in only the app's own pods, on `duckdb.port`
