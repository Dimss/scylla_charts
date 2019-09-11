{{/* Generate default globals variables */}}
{{- define "envVariables" }}
env:
- name: APP_NAME
  value: {{ .Values.application_name }}
- name: CONTAINER_NAME
  value: {{ .Values.application_name }}
- name: APPLICATION_NAME
  value: {{ .Values.application_name }}
- name: K8S_NAME
  value: {{ .Values.k8s_name }}
- name: GW_INC_HTTP
  value: {{ .Values.resources.grpcGateway.GW_INC_HTTP | quote }}
- name: GW_INC_HTTP_OPS
  value: {{ .Values.resources.grpcGateway.GW_INC_HTTP_OPS | quote }}
- name: GW_OUT_GRPC
  value: {{ .Values.resources.grpcGateway.GW_OUT_GRPC | quote }}
- name: GW_OUT_GRPC_OPS
  value: {{ .Values.resources.grpcGateway.GW_OUT_GRPC_OPS | quote }}
- name: NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: POD_IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
- name: SERVICE_ACCOUNT
  valueFrom:
    fieldRef:
      fieldPath: spec.serviceAccountName
- name: POD_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: STL_HOST_NAME
  value: $(POD_NAME).{{ .Values.service.name }}
- name: GRPC_PORT
  value: "5150"
- name: HTTP_PORT
  value: "4140"
- name: HTTP_INGERSS_PORT
  value: "4142"
- name: ui_proxy
  value: $(NODE_NAME):$(HTTP_INGERSS_PORT)
- name: FLUENTD_HOST
  value: $(NODE_NAME)
- name: FLUENTD_PORT
  value: "31111"
envFrom:
- secretRef:
    name: {{ $.Values.service.name }}
{{- end }}

{{/* Default labels */}}
{{- define "defatulLabels" }}
app: {{ .service.name  }}
did: {{ .did }}
issuer: {{ .issuer }}
tsver: {{ .tsver}}
{{- end }}

{{/* */}}
{{- define "lifecyclePortCheck" }}
{{- range $opsKey, $opsValue := .Values.ops }}
  {{- /* ======== Check liveness port configs done here ======== */}}
  {{- if eq  $opsKey "livenessPort" }}
    {{- range $port := $.Values.resources.ports}}
      {{- if eq $port.name $opsValue }}
livenessProbe:
  initialDelaySeconds: 180
  periodSeconds: 60
  tcpSocket:
    port: {{ $port.port }}
      {{- end}}
    {{- end }}
  
  {{- /* ======== Check httpGet liveness configuration ======== */}}
  {{- else if eq $opsKey "livenessHttpGet" }}
    {{- range $port := $.Values.resources.ports }}
      {{- if eq $port.name $.Values.ops.livenessHttpGet.port }}
livenessProbe:
  initialDelaySeconds: 180
  periodSeconds: 60
  httpGet:
    path: {{ $.Values.ops.livenessHttpGet.path }}
    port: {{ $port.port }}
      {{- end }}
    {{- end }}
  {{- end }}
  
  {{- /* ======== Check httpGet readiness configuration ======== */}}
  {{- if eq $opsKey "readinessHttpGet" }}
    {{- range $port := $.Values.resources.ports }}
      {{- if eq $port.name $.Values.ops.readinessHttpGet.port }}
#readinessProbe:
#  initialDelaySeconds: 180
#  periodSeconds: 60
#  httpGet:
#    path: {{ $.Values.ops.readinessHttpGet.path }}
#    port: {{ $port.port }}
      {{- end }}
    {{- end }}
  {{- end }}

{{- /* ======== Check readiness port configuration ======== */}}
  {{- if eq  $opsKey "readinessPort" }}
    {{- range $port := $.Values.resources.ports}}
      {{- if eq $port.name $opsValue }}
#readinessProbe:
#  initialDelaySeconds: 180
#  periodSeconds: 60
#  tcpSocket:
#    port: {{ $port.port }}
      {{- end}}
    {{- end }}
  {{- end}}

  {{- /* ======== Check lifecycle port configs ======== */}}
  {{- if eq $opsKey "lifecyclePort" }}
lifecycle:
  preStop:
    httpGet:
      path: "/kit/ops/v1alpha/prestop"
      port: 8091
  {{- end}}
{{- end }}
{{- end}}

{{/* Define resources  */}}
{{- define "resources" }}
#resources:
  #requests:
    #cpu: {{ .Values.resources.cpu }}
    #memory: {{ .Values.resources.mem }}
{{- end}}

{{/* Define prometheus  */}}
{{- define "prometheus" }}
{{- if .Values.prometheus }}
  {{- if (and .Values.prometheus.scrape .Values.prometheus.path .Values.prometheus.port) }}
    {{- range $port := $.Values.resources.ports}}
      {{- if eq $port.name $.Values.prometheus.port }}
prometheus.io/port: "{{ $port.port }}"
prometheus.io/scrape: "{{ $.Values.prometheus.scrape }}"
prometheus.io/path: "{{ $.Values.prometheus.path }}"
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}