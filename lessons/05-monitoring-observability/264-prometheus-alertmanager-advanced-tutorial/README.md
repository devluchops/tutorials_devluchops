# Prometheus AlertManager Advanced Tutorial

Tutorial avanzado de Prometheus AlertManager: configuración, routing, inhibition rules y best practices para alertas en producción.

## ¿Qué es AlertManager?

AlertManager es el componente de Prometheus que:
- **Recibe alertas** de Prometheus server
- **Agrupa alertas** relacionadas 
- **Enruta notificaciones** a diferentes canales
- **Silencia alertas** temporalmente
- **Inhibe alertas** dependientes

## Arquitectura Completa

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Prometheus    │───▶│  AlertManager   │───▶│  Notification   │
│   (Rules)       │    │  (Routing)      │    │   Channels      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
    Alert Rules            Processing              Slack, Email
    Evaluation             Grouping               PagerDuty
    Metrics                Throttling             Discord
                          Silencing              Webhooks
```

## Advanced AlertManager Configuration

### 1. **Sophisticated Routing**
```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@company.com'
  smtp_auth_username: 'alerts@company.com'
  smtp_auth_password: 'app-password'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default'
  routes:
  
  # Critical alerts - immediate notification
  - match:
      severity: critical
    receiver: 'critical-alerts'
    group_wait: 0s
    repeat_interval: 5m
    routes:
    - match:
        service: database
      receiver: 'dba-team'
    - match:
        service: payment
      receiver: 'payment-team'
  
  # Warning alerts - batched notifications
  - match:
      severity: warning
    receiver: 'warning-alerts'
    group_interval: 5m
    repeat_interval: 2h
  
  # Infrastructure alerts
  - match_re:
      service: 'kubernetes|docker|node'
    receiver: 'infrastructure-team'
    
  # Business hours only
  - match:
      team: business
    receiver: 'business-hours'
    active_time_intervals:
    - business_hours

# Time intervals
time_intervals:
- name: business_hours
  time_intervals:
  - times:
    - start_time: '09:00'
      end_time: '17:00'
    weekdays: ['monday:friday']
    location: 'America/New_York'

receivers:
- name: 'default'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    channel: '#alerts'
    title: 'Alert: {{ .GroupLabels.alertname }}'
    text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

- name: 'critical-alerts'
  pagerduty_configs:
  - routing_key: 'YOUR_PAGERDUTY_INTEGRATION_KEY'
    description: '{{ .GroupLabels.alertname }} - {{ .CommonAnnotations.summary }}'
    severity: 'critical'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    channel: '#critical-alerts'
    title: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'
    color: 'danger'

- name: 'dba-team'
  email_configs:
  - to: 'dba-team@company.com'
    subject: 'Database Alert: {{ .GroupLabels.alertname }}'
    body: |
      Database issue detected:
      
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      Runbook: {{ .Annotations.runbook_url }}
      {{ end }}
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/DBA/SLACK/WEBHOOK'
    channel: '#database-alerts'

inhibit_rules:
# If cluster is down, don't alert on individual services
- source_match:
    alertname: 'ClusterDown'
  target_match:
    cluster: '.*'
  equal: ['cluster']

# If node is down, don't alert on pods on that node  
- source_match:
    alertname: 'NodeDown'
  target_match_re:
    alertname: 'Pod.*'
  equal: ['instance']
```

### 2. **Advanced Alert Rules**
```yaml
# prometheus-rules.yml
groups:
- name: application.rules
  rules:
  
  # SLI/SLO based alerts
  - alert: HighErrorRate
    expr: |
      (
        rate(http_requests_total{status=~"5.."}[5m]) / 
        rate(http_requests_total[5m])
      ) > 0.05
    for: 2m
    labels:
      severity: critical
      service: api
      team: backend
    annotations:
      summary: "High error rate detected"
      description: |
        Error rate is {{ $value | humanizePercentage }} for service {{ $labels.service }}
        Current threshold: 5%
      runbook_url: "https://wiki.company.com/runbooks/high-error-rate"
      dashboard_url: "https://grafana.company.com/d/api-overview"

  # Predictive alerting
  - alert: DiskSpaceWillFillSoon
    expr: |
      predict_linear(node_filesystem_avail_bytes[6h], 4 * 3600) < 0
    for: 30m
    labels:
      severity: warning
      service: infrastructure
      team: sre
    annotations:
      summary: "Disk will be full in 4 hours"
      description: |
        Disk {{ $labels.mountpoint }} on {{ $labels.instance }} 
        will be full in approximately 4 hours based on current usage trends.

  # Multi-condition alerts
  - alert: ServiceDegraded
    expr: |
      (
        rate(http_requests_total{status="200"}[5m]) < 10 AND
        up == 1
      ) OR (
        histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
      )
    for: 5m
    labels:
      severity: warning
      service: "{{ $labels.service }}"
    annotations:
      summary: "Service performance degraded"
      description: |
        Service {{ $labels.service }} is showing signs of degradation:
        - Low request rate: {{ $value }}
        - High latency detected

  # Business metrics
  - alert: RevenueDropDetected
    expr: |
      (
        sum(rate(sales_total[1h])) < 
        sum(rate(sales_total[1h] offset 1w)) * 0.8
      )
    for: 15m
    labels:
      severity: critical
      team: business
      priority: P1
    annotations:
      summary: "Significant revenue drop detected"
      description: |
        Current hourly revenue is 20% below the same time last week.
        This requires immediate investigation.

- name: sli-slo.rules
  rules:
  # SLI: Availability
  - record: sli:availability:rate5m
    expr: |
      sum(rate(http_requests_total{status!~"5.."}[5m])) /
      sum(rate(http_requests_total[5m]))

  # SLI: Latency  
  - record: sli:latency:p99:rate5m
    expr: |
      histogram_quantile(0.99, 
        sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
      )

  # SLO Alert: 99.9% availability
  - alert: SLOViolation_Availability
    expr: sli:availability:rate5m < 0.999
    for: 5m
    labels:
      severity: critical
      slo: availability
    annotations:
      summary: "SLO violation: Availability below 99.9%"
      description: "Current availability: {{ $value | humanizePercentage }}"
```

### 3. **Custom Notification Templates**
```yaml
# templates/slack.tmpl
{{ define "slack.title" }}
{{- if eq .Status "firing" }}🔥{{- else }}✅{{- end }} 
[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] 
{{ .GroupLabels.alertname }}
{{ end }}

{{ define "slack.text" }}
{{ if .CommonAnnotations.summary }}{{ .CommonAnnotations.summary }}{{ end }}

*Affected Services:*
{{ range .GroupLabels.SortedPairs }}• {{ .Name }}: `{{ .Value }}`
{{ end }}

{{ if gt (len .Alerts.Firing) 0 }}
*Firing:*
{{ range .Alerts.Firing }}• {{ .Annotations.description }}
{{ end }}{{ end }}

{{ if gt (len .Alerts.Resolved) 0 }}
*Resolved:*
{{ range .Alerts.Resolved }}• {{ .Annotations.description }}
{{ end }}{{ end }}

{{ if .CommonAnnotations.runbook_url }}
📖 *Runbook:* {{ .CommonAnnotations.runbook_url }}{{ end }}
{{ if .CommonAnnotations.dashboard_url }}
📊 *Dashboard:* {{ .CommonAnnotations.dashboard_url }}{{ end }}
{{ end }}
```

## Advanced Features

### 1. **Alert Clustering**
```yaml
# Group similar alerts together
route:
  group_by: ['alertname', 'cluster', 'severity']
  group_wait: 30s      # Wait for more alerts before sending
  group_interval: 5m   # Wait before sending additional alerts
  repeat_interval: 4h  # How often to resend
```

### 2. **Escalation Policies**
```yaml
routes:
- match:
    severity: critical
  receiver: 'level-1-oncall'
  continue: true  # Continue to next route
  
- match:
    severity: critical
  receiver: 'level-2-escalation'
  group_wait: 5m  # Escalate after 5 minutes
```

### 3. **Conditional Routing**
```yaml
# Different alerts for different environments
- match:
    env: production
  receiver: 'prod-alerts'
  routes:
  - match:
      severity: critical
    receiver: 'prod-critical'
    
- match:
    env: staging
  receiver: 'staging-alerts'
```

## High Availability Setup

### 1. **AlertManager Cluster**
```yaml
# alertmanager-cluster.yml
global:
  # Cluster configuration
  cluster:
    listen_address: '0.0.0.0:9094'
    peers:
    - 'alertmanager-1:9094'
    - 'alertmanager-2:9094'
    - 'alertmanager-3:9094'
```

### 2. **Kubernetes Deployment**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: alertmanager
spec:
  serviceName: alertmanager
  replicas: 3
  template:
    spec:
      containers:
      - name: alertmanager
        image: prom/alertmanager:latest
        args:
        - '--config.file=/etc/alertmanager/config.yml'
        - '--cluster.listen-address=0.0.0.0:9094'
        - '--cluster.peer=alertmanager-0.alertmanager:9094'
        - '--cluster.peer=alertmanager-1.alertmanager:9094'
        - '--cluster.peer=alertmanager-2.alertmanager:9094'
```

## Monitoring AlertManager

### Key Metrics
```promql
# Alert processing metrics
alertmanager_notifications_total
alertmanager_notifications_failed_total
alertmanager_alerts_received_total
alertmanager_alerts_invalid_total

# Cluster metrics
alertmanager_cluster_members
alertmanager_cluster_health_score
```

## Best Practices

### 1. **Alert Fatigue Prevention**
- Use appropriate severities
- Implement proper grouping
- Set reasonable repeat intervals
- Use inhibition rules

### 2. **Runbook Integration**
```yaml
annotations:
  runbook_url: "https://wiki.company.com/alerts/{{ $labels.alertname }}"
  description: |
    {{ $labels.alertname }} has been triggered.
    Please check the runbook for troubleshooting steps.
```

### 3. **Testing Alerts**
```bash
# Send test alert
curl -XPOST http://alertmanager:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "TestAlert",
      "service": "test",
      "severity": "warning"
    },
    "annotations": {
      "summary": "This is a test alert"
    }
  }]'
```

## Troubleshooting

### Common Issues
1. **Alerts not firing** → Check Prometheus rules evaluation
2. **Notifications not sent** → Verify receiver configuration
3. **Duplicate alerts** → Review grouping and inhibition rules
4. **Cluster split-brain** → Check network connectivity

## Enlaces útiles

- [AlertManager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Alert Rules Guide](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [Notification Templates](https://prometheus.io/docs/alerting/latest/notifications/)
- [Tutorial en YouTube](https://youtu.be/EXAMPLE)
