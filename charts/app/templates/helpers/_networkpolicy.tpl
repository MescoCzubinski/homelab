{{/* The app's own pods, without the Postgres and DuckDB servers. */}}
{{- define "app.appPodSelector" -}}
matchExpressions:
  - key: cnpg.io/cluster
    operator: DoesNotExist
  {{- if .Values.duckdb }}
  - key: app.kubernetes.io/name
    operator: NotIn
    values:
      - {{ include "app.duckdbName" . }}
  {{- end }}
{{- end }}
