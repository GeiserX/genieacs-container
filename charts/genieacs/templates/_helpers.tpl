{{/*
Expand the name of the chart.
*/}}
{{- define "genieacs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "genieacs.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "genieacs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "genieacs.labels" -}}
helm.sh/chart: {{ include "genieacs.chart" . }}
{{ include "genieacs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "genieacs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "genieacs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the MongoDB subchart service name.
Respects mongodb.fullnameOverride when set.
*/}}
{{- define "genieacs.mongodb.fullname" -}}
{{- if .Values.mongodb.fullnameOverride -}}
{{- .Values.mongodb.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name "mongodb" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Resolve the MongoDB secret name.
Uses mongodb.auth.existingSecret when set, otherwise the subchart's auto-generated secret.
*/}}
{{- define "genieacs.mongodb.secretName" -}}
{{- if .Values.mongodb.auth.existingSecret -}}
{{- .Values.mongodb.auth.existingSecret -}}
{{- else -}}
{{- include "genieacs.mongodb.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "genieacs.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "genieacs.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Where GENIEACS_UI_JWT_SECRET comes from: "existingSecret", "value" or "extraEnvVars".
The UI signs its login tokens with this secret, so the chart has no default and
stops rendering (install, upgrade, template) when it is missing, set twice, or
left at a placeholder. Every template that needs the source includes this, so
the check runs whatever the render path.
*/}}
{{- define "genieacs.uiJwtSecret.source" -}}
{{- $name := "GENIEACS_UI_JWT_SECRET" -}}
{{- $placeholders := list "changeme" "change-me" "your-secret-here" -}}
{{- $sources := list -}}
{{- $values := list -}}
{{- if .Values.uiJwtSecret.existingSecret -}}
{{- $sources = append $sources "existingSecret" -}}
{{- end -}}
{{- $env := .Values.env | default dict -}}
{{- if hasKey $env $name -}}
{{- $sources = append $sources "value" -}}
{{- $values = append $values (get $env $name | toString) -}}
{{- end -}}
{{- range .Values.extraEnvVars -}}
{{- if eq (toString .name) $name -}}
{{- $sources = append $sources "extraEnvVars" -}}
{{- if hasKey . "value" -}}
{{- $values = append $values (toString .value) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $howTo := printf "Generate one and keep it in a Secret (recommended, it never sits in a values file):\n  kubectl create secret generic %s-ui-jwt --namespace %s --from-literal=%s=\"$(openssl rand -hex 32)\"\n  helm ... --set uiJwtSecret.existingSecret=%s-ui-jwt\nor pass the value itself:\n  helm ... --set env.%s=\"$(openssl rand -hex 32)\"" .Release.Name .Release.Namespace $name .Release.Name $name -}}
{{- if not $sources -}}
{{- fail (printf "\n\n%s is not set. The GenieACS UI signs its login tokens with it and this chart has no default.\n%s\n" $name $howTo) -}}
{{- end -}}
{{- if gt (len $sources) 1 -}}
{{- fail (printf "\n\n%s is set in more than one place (%s). Keep exactly one: uiJwtSecret.existingSecret, env.%s or an extraEnvVars entry.\n" $name (join ", " $sources) $name) -}}
{{- end -}}
{{- range $values -}}
{{- if or (not (trim .)) (has (lower (trim .)) $placeholders) -}}
{{- fail (printf "\n\n%s is %q, which is empty or a placeholder anyone can guess. Anyone who knows it can forge a UI login.\n%s\n" $name . $howTo) -}}
{{- end -}}
{{- end -}}
{{- first $sources -}}
{{- end -}}
