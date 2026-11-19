{{- define "app.postgresName" -}}
{{ .Release.Name }}-pg
{{- end }}

{{- define "app.duckdbName" -}}
{{ .Release.Name }}-duckdb
{{- end }}
