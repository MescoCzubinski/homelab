{{- define "app.postgresName" -}}
{{ .Release.Name }}-pg
{{- end }}

{{- define "app.duckdbName" -}}
{{ .Release.Name }}-duckdb
{{- end }}

{{/* Quack's default port */}}
{{- define "app.duckdbPort" -}}
9494
{{- end }}
