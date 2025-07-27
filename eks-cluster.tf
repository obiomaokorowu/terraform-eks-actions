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
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

output "cluster_id" {
  value = module.eks.cluster_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.0.0"

  name               = "app-eks-cluster"  # corrected from cluster_name
  kubernetes_version = "1.31"
  subnet_ids         = module.myapp-vpc.private_subnets
  vpc_id             = module.myapp-vpc.vpc_id
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition 
  endpoint_private_access = false
  endpoint_public_access  = true
  enable_cluster_creator_admin_permissions = true
  access_entries = {
  admin = {
    kubernetes_groups = ["system:masters"]
    principal_arn     = "arn:aws:iam::361769567498:role/EKSAdminRole"
    type              = "STANDARD"

    policy_associations = {
      view = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
        access_scope = {
          type = "cluster"
        }
      }
      full = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSFullAccessPolicy"
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
      launch_template = {
        elastic_gpu_specifications    = null
        elastic_inference_accelerator = null
      }
    }
  }

  depends_on = [module.myapp-vpc]
}

