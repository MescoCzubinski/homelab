{{- define "app.podSpec" -}}
{{- $root := .root }}
{{- with .workload -}}
automountServiceAccountToken: false
{{- with $root.Values.imagePullSecrets }}
imagePullSecrets:
  {{- range . }}
  - name: {{ . }}
  {{- end }}
{{- end }}
securityContext:
  seccompProfile:
    type: RuntimeDefault
containers:
  - name: {{ .name }}
    image: {{ .image.repository }}:{{ .image.tag }}
    imagePullPolicy: IfNotPresent
    {{- with .command }}
    command:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    securityContext:
      {{- toYaml (mergeOverwrite (deepCopy $root.Values.securityContext) (.securityContext | default dict)) | nindent 6 }}
      {{- with .runAsUser }}
      runAsUser: {{ . }}
      {{- end }}
    {{- if or .env .secretEnv }}
    env:
      {{- with .env }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
      {{- range $name, $secret := .secretEnv }}
      {{- $ref := splitList "/" $secret }}
      - name: {{ $name }}
        valueFrom:
          secretKeyRef:
            name: {{ first $ref }}
            key: {{ if gt (len $ref) 1 }}{{ last $ref }}{{ else }}{{ $name }}{{ end }}
      {{- end }}
    {{- end }}
    {{- if .port }}
    ports:
      - name: http
        containerPort: {{ .port }}
    readinessProbe:
      {{- with .probe }}
      httpGet:
        path: {{ .path }}
        port: http
      {{- else }}
      tcpSocket:
        port: http
      {{- end }}
      periodSeconds: 5
    {{- end }}
    {{- with .resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    volumeMounts:
      - name: tmp
        mountPath: /tmp
      {{- if .duckdb }}
      - name: data
        mountPath: /data
      {{- end }}
      {{- range $i, $path := .writablePaths }}
      - name: writable-{{ $i }}
        mountPath: {{ $path }}
      {{- end }}
volumes:
  - name: tmp
    emptyDir: {}
  {{- if .duckdb }}
  - name: data
    persistentVolumeClaim:
      claimName: {{ .name }}
  {{- end }}
  {{- range $i, $path := .writablePaths }}
  - name: writable-{{ $i }}
    emptyDir: {}
  {{- end }}
{{- end }}
{{- end }}
