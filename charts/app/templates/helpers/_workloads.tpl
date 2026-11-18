{{/* The workload with the top-level image as its default. */}}
{{- define "app.withImage" -}}
{{- toYaml (mergeOverwrite (dict "image" (deepCopy (.root.Values.image | default dict))) (deepCopy .workload)) }}
{{- end }}

{{/* Components and the DuckDB server, rendered as Deployments. */}}
{{- define "app.workloads" -}}
{{- $workloads := list }}
{{- range .Values.components }}
{{- $workloads = append $workloads (fromYaml (include "app.withImage" (dict "root" $ "workload" .))) }}
{{- end }}
{{- if .Values.duckdb }}
{{- $workloads = append $workloads (fromYaml (include "app.duckdb" .)) }}
{{- end }}
{{- toYaml $workloads }}
{{- end }}

{{/* The DuckDB server. Its image runs as uid 1000, keeps its file in /data and reads QUACK_PORT and QUACK_TOKEN. */}}
{{- define "app.duckdb" -}}
name: {{ include "app.duckdbName" . }}
image:
  {{- toYaml .Values.duckdb.image | nindent 2 }}
port: {{ include "app.duckdbPort" . }}
runAsUser: 1000
env:
  - name: QUACK_PORT
    value: {{ include "app.duckdbPort" . | quote }}
secretEnv:
  QUACK_TOKEN: {{ include "app.duckdbName" . }}/token
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: "1"
    memory: 2Gi
duckdb: true
{{- end }}

{{- define "app.jobs" -}}
{{- $jobs := list }}
{{- range .Values.jobs }}
{{- $jobs = append $jobs (fromYaml (include "app.withImage" (dict "root" $ "workload" .))) }}
{{- end }}
{{- toYaml $jobs }}
{{- end }}
