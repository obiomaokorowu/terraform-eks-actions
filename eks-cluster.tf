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
  version = "19.15.3"

  cluster_name    = "app-eks-cluster"
  cluster_version = "1.28"

  vpc_id     = module.myapp-vpc.vpc_id
  subnet_ids = module.myapp-vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false

  enable_irsa = true

  eks_managed_node_groups = {
    workers = {
      name           = "worker-nodes"
      instance_types = ["t2.small"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      key_name       = "may_key"
      partition      = "aws"

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }

  # Map your current IAM user/role for cluster access
  map_users = [
    {
      userarn  = data.aws_caller_identity.current.arn
      username = split("/", data.aws_caller_identity.current.arn)[1]
      groups   = ["system:masters"]
    }
  ]

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
