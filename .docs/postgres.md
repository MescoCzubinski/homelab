# Postgres

## Overview

One shared PostgreSQL 17 instance for apps that need a database, run by [CloudNativePG](https://cloudnative-pg.io).

- **Operator:** `cnpg` Application, upstream chart in namespace `cnpg-system`
- **Cluster:** `pg` in namespace `postgres` ([infra/postgres/cluster.yaml](../infra/postgres/cluster.yaml)), one instance, no replicas
- **Superuser:** disabled (`enableSuperuserAccess: false`), each app gets its own role and database
- **Sync wave:** the `postgres` Application is at wave `1`

## Storage

A static `local` PersistentVolume ([persistentvolume.yaml](../infra/postgres/persistentvolume.yaml)) on the host, 10 Gi, `Retain`:

- **Path:** `/home/server/postgres/data`
- **Node affinity:** `kubernetes.io/hostname: myserver.home`, so the PV is tied to this node. It has to be changed if the node is renamed or replaced.
- **StorageClass:** `local-postgres`, no provisioner, `WaitForFirstConsumer`

There are **no backups yet**. Together with the tools' data, `/home/server/` is what needs a backup, but a file copy of a running Postgres is not consistent. A proper solution is CNPG backups (Barman) or `pg_dump`.

## Access

[NetworkPolicies](../infra/postgres/networkpolicy.yaml) in the `postgres` namespace:

| policy                 | allows                                                                                 |
| ---------------------- | -------------------------------------------------------------------------------------- |
| `nobody-to-postgres`   | default-deny ingress for the namespace                                                 |
| `operator-to-postgres` | `cnpg-system` to `pg` on `5432` and `8000` (status)                                    |
| `<app>-to-postgres`    | the `<app>` namespace to `pg` on `5432`, one policy per app (now: `atlas-to-postgres`) |

Namespaces are matched by their automatic `kubernetes.io/metadata.name` label, so there is no label to set by hand.
