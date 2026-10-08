{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ .component.name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- end }}

{{- define "app.labels" -}}
{{ include "app.selectorLabels" . }}
app.kubernetes.io/version: {{ .component.image.tag | quote }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- end }}
