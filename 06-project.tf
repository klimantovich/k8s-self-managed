locals {
  cert_secret_name = "${var.project_application_name}-tls"
  cert_host_name   = "klim4ntovich.online"
}

resource "kubectl_manifest" "argocd_project" {
  yaml_body  = <<-EOF
    apiVersion: argoproj.io/v1alpha1
    kind: AppProject
    metadata:
      name: ${var.argocd_project_name}
      namespace: ${var.argocd_chart_namespace}
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      sourceRepos:
        - ${var.project_repository}
      destinations:
        - server: https://kubernetes.default.svc
          name: in-cluster
          namespace: "${var.project_namespace}"
      clusterResourceWhitelist:
        - group: "*"
          kind: Namespace
      namespaceResourceWhitelist:
        - group: "apps"
          kind: Deployment
        - group: "*"
          kind: ConfigMap
        - group: "*"
          kind: Secret
        - group: "networking.k8s.io"
          kind: Ingress
        - group: "*"
          kind: Service
  EOF
  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_application" {
  yaml_body = <<-EOF
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: ${var.project_application_name}
      namespace: ${var.argocd_chart_namespace}
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: ${var.argocd_project_name}
      source:
        repoURL: ${var.project_repository}
        targetRevision: ${var.project_repository_branch}
        path: ${var.project_repository_path}
        helm:
          valueFiles:
            - "../../values/gymmanagement-${var.environment}.yaml"
            - "../../values/gymmanagement-${var.environment}-image.yaml"
          valuesObject:
            ingress:
              enabled: true
              hosts:
                - host: ${local.cert_host_name}
                  paths:
                    - path: /
                      pathType: Prefix
              tls:
                - secretName: ${local.cert_secret_name}
                  hosts:
                    - ${local.cert_host_name}
              httpAuth:
                user: ${var.httpAuthUser}
                password: ${random_password.nginx_password.result}
            configmap:
              db_user: ${var.db_user}
              db_name: ${var.db_name}
              db_host: ${module.database.instance_address}
            secret:
              db_password: ${random_password.db_password.result}
      destination:
        server: https://kubernetes.default.svc
        namespace: ${var.project_namespace}
      syncPolicy:
        automated: {}
        syncOptions:
          - CreateNamespace=true
  EOF

  depends_on = [kubectl_manifest.argocd_project]
}

#-----------------------------------------------
# Generate SSL certs for ingress
#-----------------------------------------------
resource "kubectl_manifest" "project_cert" {
  yaml_body  = <<-EOF
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: ${var.project_application_name}
      namespace: ${var.project_namespace}
    spec:
      secretName: ${local.cert_secret_name}
      renewBefore: 240h
      duration: 2160h
      commonName: ${local.cert_host_name}
      dnsNames:
      - klim4ntovich.online
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer
  EOF
  depends_on = [kubectl_manifest.argocd_application]
}
