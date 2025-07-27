provider "kubernetes" {
  #load_config_file = "false"
  host = data.aws_eks_cluster.app-cluster.endpoint
  token = data.aws_eks_cluster_auth.app-cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app-cluster.certificate_authority.0.data)
}

data "aws_eks_cluster" "app-cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}


data "aws_eks_cluster_auth" "app-cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}
output "cluster_id" {
  value = data.aws_eks_cluster.app-cluster.id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.36.0"

  cluster_name = "app-eks-cluster"
  cluster_version = "1.31"
  subnet_ids = module.myapp-vpc.private_subnets
  vpc_id = module.myapp-vpc.vpc_id
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  tags = {
    environment = "development"
    application = "app"
    team        = "devops"
  }

  eks_managed_node_groups = {
    worker-nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 3
      instance_types = ["t2.small"]
      key_name       = "may_key"
      launch_template = {
        elastic_gpu_specifications = null  # Disable
        elastic_inference_accelerator = null  # Disable
      }
    }
  }
  depends_on = [module.myapp-vpc]
}
