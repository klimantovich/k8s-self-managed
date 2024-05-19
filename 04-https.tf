data "google_dns_managed_zone" "cluster" {
  name = "klim4ntovich-online"
}

#-----------------------------------------------
# A-record for project ingress
#-----------------------------------------------
resource "google_dns_record_set" "project" {
  name         = data.google_dns_managed_zone.cluster.dns_name
  managed_zone = data.google_dns_managed_zone.cluster.name
  type         = "A"
  ttl          = 300

  rrdatas = [module.cluster.cluster_ip]
}

#-----------------------------------------------
# A-record for argocd ingress
#-----------------------------------------------
resource "google_dns_record_set" "argocd" {
  name         = "argocd.${data.google_dns_managed_zone.cluster.dns_name}"
  managed_zone = data.google_dns_managed_zone.cluster.name
  type         = "A"
  ttl          = 300

  rrdatas = [module.cluster.cluster_ip]
}

#-----------------------------------------------
# Install cert-manager & Create letsencrypt cert issuer
#-----------------------------------------------
locals {
  cert_manager_namespace = "cert-manager"
  cert_manager_version   = "1.14.5"
}

resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = local.cert_manager_namespace
  create_namespace = true
  version          = "v${local.cert_manager_version}"

  set {
    name  = "installCRDs"
    value = true
  }

  depends_on = [module.cluster]

}

resource "kubectl_manifest" "cert_issuer" {

  yaml_body = <<-EOF
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
      namespace: ${local.cert_manager_namespace}
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: vitali@gmail.com
        privateKeySecretRef:
          name: letsencrypt-prod
        solvers:
        - http01:
            ingress:
              class: nginx
  EOF

  depends_on = [helm_release.cert-manager]
}
