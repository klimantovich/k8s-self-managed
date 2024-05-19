resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = var.argocd_repository
  chart            = "argo-cd"
  namespace        = var.argocd_chart_namespace
  create_namespace = var.argocd_chart_create_namespace
  version          = "6.7.10"

  values = [file(var.argocd_values_path)]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = bcrypt(random_password.argocd_password.result)
  }

  depends_on = [module.cluster]

  lifecycle {
    ignore_changes = [set_sensitive]
  }

}
