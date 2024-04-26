resource "aws_secretsmanager_secret" "kubeconfig_secret" {
  name        = local.kubeconfig_secret_name
  description = "Kubeconfig to access cluster"
}

resource "aws_secretsmanager_secret" "kubeadm_ca" {
  name        = local.kubeadm_ca_secret_name
  description = "Kubeadm CA"
}

resource "aws_secretsmanager_secret" "kubeadm_ca_hash" {
  name        = local.kubeadm_ca_hash_secret_name
  description = "Kubeadm CA Hash"
}

resource "aws_secretsmanager_secret" "kubeadm_token" {
  name        = local.kubeadm_token_secret_name
  description = "Kubeadm token"
}

resource "aws_secretsmanager_secret" "kubeadm_cert" {
  name        = local.kubeadm_certificate_key_secret_name
  description = "Kubeadm Certificate Key"
}


resource "aws_secretsmanager_secret_version" "kubeconfig_secret_default" {
  secret_id     = aws_secretsmanager_secret.kubeconfig_secret.id
  secret_string = local.secret_placeholder
}

resource "aws_secretsmanager_secret_version" "kubeadm_ca_hash_default" {
  secret_id     = aws_secretsmanager_secret.kubeadm_ca_hash.id
  secret_string = local.secret_placeholder
}

resource "aws_secretsmanager_secret_version" "kubeadm_token_default" {
  secret_id     = aws_secretsmanager_secret.kubeadm_token.id
  secret_string = local.secret_placeholder
}

resource "aws_secretsmanager_secret_version" "kubeadm_cert_default" {
  secret_id     = aws_secretsmanager_secret.kubeadm_cert.id
  secret_string = local.secret_placeholder
}

resource "aws_secretsmanager_secret_version" "kubeadm_ca_default" {
  secret_id     = aws_secretsmanager_secret.kubeadm_ca.id
  secret_string = local.secret_placeholder
}
