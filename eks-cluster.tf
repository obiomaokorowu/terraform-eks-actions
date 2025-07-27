provider "kubernetes" {
  host                   = data.aws_eks_cluster.app-cluster.endpoint
  token                  = data.aws_eks_cluster_auth.app-cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app-cluster.certificate_authority[0].data)
}

data "aws_eks_cluster" "app-cluster" {
  name = module.eks.cluster_id
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "app-cluster" {
  name = module.eks.cluster_id
  depends_on = [module.eks]
}
output "cluster_id" {
  value = module.eks.cluster_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.0.4"

  name               = "app-eks-cluster"  
  kubernetes_version = "1.29" # Updated to a supported version
  subnet_ids         = module.myapp-vpc.private_subnets
  vpc_id             = module.myapp-vpc.vpc_id
  endpoint_private_access = false
  endpoint_public_access  = true
  enable_cluster_creator_admin_permissions = false

  access_entries = {
    github-actions-admin = {
      principal_arn     = "arn:aws:iam::361769567498:role/github-actions-terraform"
      kubernetes_groups = ["system:masters"]
      type              = "STANDARD"
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
    environment = "development"
    application = "app"
    team        = "devops"
  }

  eks_managed_node_groups = {
    worker-nodes = {
      min_size       = 1
      max_size       = 3
      desired_size   = 3
      instance_types = ["t2.small"]
      key_name       = "may_key"
      
      # These belong here in the node group configuration
      partition  = "aws"
      account_id = "361769567498"

    }
  }

  depends_on = [module.myapp-vpc]
}

