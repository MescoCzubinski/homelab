#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 4 ] || [[ ! $2 =~ ^[a-z0-9.-]+$ ]]; then
  echo "usage: create-secret.sh <namespace> <name> [key] [value]" >&2
  echo "       create-secret.sh <namespace> ghcr-pull" >&2
  exit 1
fi

namespace=$1
name=$2
key=${3:-}
value=${4:-}
type=""

if [ "$name" = ghcr-pull ]; then
  if [ $# -gt 2 ]; then
    echo "ghcr-pull takes no key or value, it is copied from the cluster, nothing changed" >&2
    exit 1
  fi

  sources=$(kubectl get secrets -A --field-selector metadata.name=ghcr-pull -o jsonpath='{.items[*].metadata.namespace}')
  source=${sources%% *}
  if [ -z "$source" ]; then
    echo "no ghcr-pull in the cluster to copy, nothing changed" >&2
    exit 1
  fi
  key=.dockerconfigjson
  value=$(kubectl get secret ghcr-pull -n "$source" -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d)
  type=kubernetes.io/dockerconfigjson
else
  if [ $# -lt 4 ] && [ ! -t 0 ]; then
    echo "key and value must be parameters or typed at the prompt, nothing changed" >&2
    exit 1
  fi
  if [ $# -lt 3 ]; then
    read -rp "key: " key
  fi
  if [ $# -lt 4 ]; then
    read -rsp "value: " value
    echo
  fi
fi
if [[ ! $key =~ ^[-._a-zA-Z0-9]+$ ]] || [ -z "$value" ]; then
  echo "invalid key or empty value, nothing changed" >&2
  exit 1
fi

root=$(git rev-parse --show-toplevel)
dir=""
for tier in apps tools infra; do
  if [ -d "$root/$tier/$namespace" ]; then
    dir=$root/$tier/$namespace
  fi
done
if [ -z "$dir" ]; then
  echo "no apps/$namespace, tools/$namespace or infra/$namespace, nothing changed" >&2
  exit 1
fi
file=$dir/sealed-secret.yaml
touch "$file"

sealed=$(printf '%s' "$value" \
  | kubeseal --raw --cert "$root/infra/sealed-secrets/pub-cert.pem" --namespace "$namespace" --name "$name")

if grep -qxF "  name: $name" "$file"; then
  export name key sealed
  awk '
    function put() { print "    " ENVIRON["key"] ": " ENVIRON["sealed"]; done = 1 }
    /^---$/ { if (target && !done && inenc) put(); target = 0 }
    $0 == "  name: " ENVIRON["name"] { target = 1 }
    target && !done && inenc && !/^    / { put(); inenc = 0 }
    target && !done && inenc && index($0, "    " ENVIRON["key"] ": ") == 1 { put(); next }
    target && $0 == "  encryptedData:" { inenc = 1 }
    { print }
    END { if (target && !done && inenc) put() }
  ' "$file" >"$file.tmp"
  mv "$file.tmp" "$file"
else
  cat >>"$file" <<EOF
---
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
  name: $name
  namespace: $namespace
spec:
  encryptedData:
    $key: $sealed
  template:
    metadata:
      name: $name
      namespace: $namespace
EOF
  if [ -n "$type" ]; then
    echo "    type: $type" >>"$file"
  fi
fi
