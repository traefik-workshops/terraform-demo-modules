locals {
  loki_exporter = var.enable_loki ? ["otlphttp/loki"] : []
  tempo_exporter = var.enable_tempo ? ["otlphttp/tempo"] : []
  newrelic_exporter = var.enable_new_relic ? ["otlphttp/nri"] : []
  dash0_exporter = var.enable_dash0 ? ["otlphttp/dash0"] : []
  honeycomb_exporter = var.enable_honeycomb ? ["otlphttp/honeycomb"] : []
  prometheus_exporter = var.enable_prometheus ? ["prometheus"] : []
  
  log_exporters = concat(local.loki_exporter, local.newrelic_exporter, local.dash0_exporter, local.honeycomb_exporter)
  trace_exporters = concat(local.tempo_exporter, local.newrelic_exporter, local.dash0_exporter, local.honeycomb_exporter)
  metric_exporters = concat(local.newrelic_exporter, local.dash0_exporter, local.honeycomb_exporter, local.prometheus_exporter)

  logs_pipeline = length(local.log_exporters) > 0 ?concat([
    {
      name = "config.service.pipelines.logs.receivers[0]"
      value = "otlp"
    },
    {
      name = "config.service.pipelines.logs.processors[0]"
      value = "batch"
    }
  ], [ for exporter in local.log_exporters : {
    name = "config.service.pipelines.logs.exporters[${index(local.log_exporters, exporter)}]"
    value = exporter
  }]) : []

  metrics_pipeline = length(local.metric_exporters) > 0 ?concat([
    {
      name = "config.service.pipelines.metrics.receivers[0]"
      value = "otlp"
    },
    {
      name = "config.service.pipelines.metrics.processors[0]"
      value = "batch"
    }
  ], var.enable_prometheus ? [
    {
      name = "config.service.pipelines.metrics.receivers[1]"
      value = "spanmetrics"
    }
  ] : [], [ for exporter in local.metric_exporters : {
    name = "config.service.pipelines.metrics.exporters[${index(local.metric_exporters, exporter)}]"
    value = exporter
  }]) : []

  traces_pipeline = length(local.trace_exporters) > 0 ?concat([
    {
      name = "config.service.pipelines.traces.receivers[0]"
      value = "otlp"
    },
    {
      name = "config.service.pipelines.traces.processors[0]"
      value = "batch"
    }
  ], [ for exporter in local.trace_exporters : {
    name = "config.service.pipelines.traces.exporters[${index(local.trace_exporters, exporter)}]"
    value = exporter
  }], var.enable_prometheus ? [
    {
      name = "config.service.pipelines.traces.exporters[${length(local.trace_exporters)}]"
      value = "spanmetrics"
    }
  ] : []) : []

  service_pipelines = concat(local.logs_pipeline, local.metrics_pipeline, local.traces_pipeline)
}

resource "helm_release" "opentelemetry" {
  name       = var.name
  namespace  = var.namespace
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = "0.127.2"
  timeout    = 900
  atomic     = true

  set = concat(local.service_pipelines, [
    {
      name = "mode"
      value = "deployment"
    },
    {
      name = "image.repository"
      value = "otel/opentelemetry-collector-contrib"
    },
    {
      name = "image.tag"
      value = "latest"
    },
    {
      name = "ports.metrics.enabled"
      value = true
    },
    {
      name = "ports.metrics.containerPort"
      value = 8889
    },
    {
      name = "ports.metrics.servicePort"
      value = 8889
    },
    {
      name = "config.receivers.otlp.protocols.http.endpoint"
      value = "0.0.0.0:4318"
    },
    {
      name = "config.receivers.otlp.protocols.grpc.endpoint"
      value = "0.0.0.0:4317"
    },
    {
      name = "config.processors.batch.timeout"
      value = "5s"
    },
    {
      name = "config.connectors.spanmetrics.exemplars.enabled"
      value = true
    },
    {
      name = "config.connectors.spanmetrics.dimensions[0].name"
      value = "entry_point"
    },
    {
      name = "config.connectors.spanmetrics.dimensions[1].name"
      value = "server.address"
    },
    {
      name = "config.connectors.spanmetrics.dimensions[2].name"
      value = "http.request.method"
    },
    {
      name = "config.connectors.spanmetrics.dimensions[3].name"
      value = "http.response.status_code"
    },
    {
      name = "config.connectors.spanmetrics.dimensions[4].name"
      value = "http.response.header.x-cache-status"
    },
    {
      name = "config.connectors.spanmetrics.resource_metrics_key_attributes"
      value = "service.name"
    },
    {
      name = "config.exporters.otlphttp\\/loki.endpoint"
      value = "http://loki.traefik-observability:3100/otlp"
    },
    {
      name = "config.exporters.otlphttp\\/loki.tls.insecure"
      value = true
    },
    {
      name = "config.exporters.otlphttp\\/tempo.endpoint"
      value = "http://tempo.traefik-observability:4318"
    },
    {
      name = "config.exporters.otlphttp\\/tempo.tls.insecure"
      value = true
    },
    {
      name = "config.exporters.otlphttp\\/nri.endpoint"
      value = var.newrelic_endpoint
    },
    {
      name = "config.exporters.otlphttp\\/nri.headers.api-key"
      value = var.newrelic_license_key
    },
    {
      name = "config.exporters.otlphttp\\/honeycomb.endpoint"
      value = var.honeycomb_endpoint
    },
    {
      name = "config.exporters.otlphttp\\/honeycomb.headers.x-honeycomb-team"
      value = var.honeycomb_api_key
    },
    {
      name = "config.exporters.otlphttp\\/honeycomb.headers.x-honeycomb-dataset"
      value = var.honeycomb_dataset
    },
    {
      name = "config.exporters.otlphttp\\/dash0.endpoint"
      value = var.dash0_endpoint
    },
    {
      name = "config.exporters.otlphttp\\/dash0.headers.Authorization"
      value = "Bearer ${var.dash0_auth_token}"
    },
    {
      name = "config.exporters.otlphttp\\/dash0.headers.Dash0-Dataset"
      value = var.dash0_dataset
    },
    {
      name = "config.exporters.prometheus.endpoint"
      value = "0.0.0.0:8889"
    }
  ])
}
