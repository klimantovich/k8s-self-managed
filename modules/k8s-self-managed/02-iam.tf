#----------------------------------------
# IAM roles for cluster Nodes
#----------------------------------------

resource "aws_iam_policy" "k8s-control-node" {
  name        = "k8s-control-node"
  description = "Policy for self-managed k8s master nodes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:DescribeAvailabilityZones",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifyVolume",
          "ec2:AttachVolume",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteVolume",
          "ec2:DetachVolume",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeVpcs",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:AttachLoadBalancerToSubnets",
          "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateLoadBalancerPolicy",
          "elasticloadbalancing:CreateLoadBalancerListeners",
          "elasticloadbalancing:ConfigureHealthCheck",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancerListeners",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DetachLoadBalancerFromSubnets",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancerPolicies",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
          "iam:CreateServiceLinkedRole",
          "kms:DescribeKey"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "k8s-control-node" {
  name = "k8s-control-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

}

resource "aws_iam_role_policy_attachment" "k8s-control-node" {
  role       = aws_iam_role.k8s-control-node.name
  policy_arn = aws_iam_policy.k8s-control-node.arn
}


resource "aws_iam_policy" "k8s-worker-node" {
  name        = "k8s-worker-node"
  description = "Policy for self-managed k8s worker nodes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchGetImage"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "k8s-worker-node" {
  name = "k8s-worker-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

}

resource "aws_iam_role_policy_attachment" "k8s-worker-node" {
  role       = aws_iam_role.k8s-worker-node.name
  policy_arn = aws_iam_policy.k8s-worker-node.arn
}


resource "aws_iam_policy" "access_to_k8s_secrets" {
  name        = "access-to-k8s-secrets"
  description = "Provide Access to k8s secretss"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:RestoreSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:CreateSecret",
          "secretsmanager:UpdateSecretVersionStage",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:UpdateSecret"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_secretsmanager_secret.kubeconfig_secret.arn}",
          "${aws_secretsmanager_secret.kubeadm_ca.arn}",
          "${aws_secretsmanager_secret.kubeadm_token.arn}",
          "${aws_secretsmanager_secret.kubeadm_cert.arn}"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "access_to_k8s_secrets_master" {
  role       = aws_iam_role.k8s-control-node.name
  policy_arn = aws_iam_policy.access_to_k8s_secrets.arn
}

resource "aws_iam_role_policy_attachment" "access_to_k8s_secrets_worker" {
  role       = aws_iam_role.k8s-worker-node.name
  policy_arn = aws_iam_policy.access_to_k8s_secrets.arn
}

resource "aws_iam_instance_profile" "k8s-control-node" {
  name = "k8s-control-node-profile"
  role = aws_iam_role.k8s-control-node.name
}

resource "aws_iam_instance_profile" "k8s-worker-node" {
  name = "k8s-worker-node-profile"
  role = aws_iam_role.k8s-worker-node.name
}
