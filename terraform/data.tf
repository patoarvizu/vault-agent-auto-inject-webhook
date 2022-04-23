data kubernetes_namespace ns {
  for_each = var.create_namespace ? {} : {"ns": true}
  metadata {
    name = var.namespace_name
  }
}