#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 4 ] || [[ ! $2 =~ ^[a-z0-9.-]+$ ]]; then
  echo "usage: create-secret.sh <namespace> <name> [key] [value]" >&2
  exit 1
fi

namespace=$1
name=$2
key=${3:-}
value=${4:-}

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

export name key sealed
if [ -n "$(yq 'select(.metadata.name == strenv(name)) | .metadata.name' "$file")" ]; then
  yq -i '(select(.metadata.name == strenv(name)) | .spec.encryptedData[strenv(key)]) = strenv(sealed)' "$file"
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
fi
