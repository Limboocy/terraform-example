{
  "title": "${cluster_name} - ${environment} overview",
  "description": "Managed by Terraform. Do not edit in the Datadog UI — changes will be reverted on next apply.",
  "layout_type": "ordered",
  "reflow_type": "fixed",
  "widgets": [
    {
      "definition": {
        "title": "Node CPU %",
        "type": "timeseries",
        "requests": [
          {
            "display_type": "line",
            "q": "avg:kubernetes.cpu.usage.total{cluster_name:${cluster_name}} by {node}"
          }
        ]
      }
    },
    {
      "definition": {
        "title": "Node memory %",
        "type": "timeseries",
        "requests": [
          {
            "display_type": "line",
            "q": "avg:kubernetes.memory.usage_pct{cluster_name:${cluster_name}} by {node}"
          }
        ]
      }
    },
    {
      "definition": {
        "title": "Running pods by namespace",
        "type": "timeseries",
        "requests": [
          {
            "display_type": "bars",
            "q": "sum:kubernetes.pods.running{cluster_name:${cluster_name}} by {kube_namespace}"
          }
        ]
      }
    },
    {
      "definition": {
        "title": "Node filesystem usage %",
        "type": "timeseries",
        "requests": [
          {
            "display_type": "line",
            "q": "avg:kubernetes.filesystem.usage_pct{cluster_name:${cluster_name}} by {node}"
          }
        ]
      }
    }
  ]
}
