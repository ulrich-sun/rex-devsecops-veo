{{- define "recipe-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "recipe-app.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "recipe-app.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "recipe-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version -}}
{{- end }}

{{- define "recipe-app.labels" -}}
app.kubernetes.io/name: {{ include "recipe-app.name" . }}
helm.sh/chart: {{ include "recipe-app.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
