module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.10.0" # Latest as of July 2024

  cluster_name                   = "app-eks-cluster"
  cluster_version                = "1.30"
  cluster_endpoint_public_access = true

  vpc_id     = module.myapp-vpc.vpc_id
  subnet_ids = module.myapp-vpc.private_subnets

  # Modern auth configuration (recommended approach)
  enable_cluster_creator_admin_permissions = true

  # Alternative legacy auth mapping (still supported)
  manage_aws_auth_configmap = true
  aws_auth_users = [
    {
      userarn  = data.aws_caller_identity.current.arn
      username = element(split("/", data.aws_caller_identity.current.arn), length(split("/", data.aws_caller_identity.current.arn)) - 1)
      groups   = ["system:masters"]
    }
  ]

  # Modern addon management
  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { 
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI = "true"
        }
      })
    }
  }

  eks_managed_node_groups = {
    workers = {
      name         = "worker-nodes"
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.small"] # t2.small is deprecated
      capacity_type  = "ON_DEMAND"
      key_name       = "may_key"

      # Modern launch template
      create_launch_template = true
      launch_template_tags  = {
        Name = "worker-nodes"
      }
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "development"
  }
}


# Kubernetes provider configuration
data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

output "kubeconfig" {
  value = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}
