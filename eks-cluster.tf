provider "kubernetes" {
  host                   = data.aws_eks_cluster.app-cluster.endpoint
  token                  = data.aws_eks_cluster_auth.app-cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app-cluster.certificate_authority[0].data)
}

data "aws_eks_cluster" "app-cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "app-cluster" {
  name = module.eks.cluster_name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"  # Using a stable version that doesn't have this issue

  cluster_name    = "app-eks-cluster"
  cluster_version = "1.28"  # Supported EKS version

  vpc_id     = module.myapp-vpc.vpc_id
  subnet_ids = module.myapp-vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  # IAM Role for Service Account (IRSA) configuration
  enable_irsa = true

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    workers = {
      name           = "worker-nodes"
      instance_types = ["t2.small"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2

      # Use existing key pair
      key_name = "may_key"

      # Required to avoid the count argument error
      partition = "aws"

      # IAM Role configuration
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }

  # Access entry for GitHub Actions
  cluster_access_entries = {
    github-actions = {
      principal_arn      = "arn:aws:iam::361769567498:role/github-actions-terraform"
      kubernetes_groups = ["system:masters"]
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    Environment = "development"
    Application = "app"
    Team        = "devops"
  }
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}
