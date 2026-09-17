{
  "title": "${cluster_name} - ${environment} overview",
  "layout_type": "ordered",
  "widgets": [
    {
      "definition": {
        "type": "timeseries",
        "title": "Node CPU %%",
        "requests": [
          { "q": "avg:kubernetes.cpu.usage.total{cluster_name:${cluster_name}} by {node}" }
        ]
      }
    },
    {
      "definition": {
        "type": "timeseries",
        "title": "Node memory %%",
        "requests": [
          { "q": "avg:kubernetes.memory.usage_pct{cluster_name:${cluster_name}} by {node}" }
        ]
      }
    }
  ]
}
