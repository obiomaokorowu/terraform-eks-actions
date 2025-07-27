
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "app-eks-cluster"
  cluster_version = "1.32"

  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    example = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 5
      desired_size   = 2
    }
  }

  vpc_id     = module.myapp-vpc.vpc_id
  subnet_ids = module.myapp-vpc.private_subnets

  tags = {
    Name        = "app-eks-cluster"
    Environment = "development"
    Terraform   = "true"
  }

}

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "20.11.0"
#
#   cluster_name    = "app-eks-cluster"
#   cluster_version = "1.30"
#
#   vpc_id     = module.myapp-vpc.vpc_id
#   subnet_ids = module.myapp-vpc.private_subnets
#
#   cluster_endpoint_public_access = true
#
#   # Modern auth configuration
#   enable_cluster_creator_admin_permissions = true
#
#   # Cluster addons without conflicts
#   cluster_addons = {
#     coredns = {
#       most_recent = true
#     }
#     kube-proxy = {
#       most_recent = true
#     }
#     vpc-cni = {
#       most_recent = true
#       configuration_values = jsonencode({
#         env = {
#           ENABLE_POD_ENI = "true"
#         }
#       })
#     }
#   }
#
#   # Node group configuration without problematic GPU settings
#   eks_managed_node_groups = {
#     workers = {
#       name         = "worker-nodes"
#       min_size     = 1
#       max_size     = 3
#       desired_size = 2
#
#       instance_types = ["t3.small"] # Updated from t2.small
#       capacity_type  = "ON_DEMAND"
#       key_name       = "may_key"
#
#       # Simplified launch template
#       launch_template_name = "worker-nodes"
#       launch_template_tags = {
#         Name = "worker-nodes"
#       }
#     }
#   }
#
#   tags = {
#     Terraform   = "true"
#     Environment = "development"
#   }
# }
#
# # Kubernetes provider configuration (REQUIRED)
# data "aws_eks_cluster" "this" {
#   name = module.eks.cluster_name
# }
#
# data "aws_eks_cluster_auth" "this" {
#   name = module.eks.cluster_name
# }
#
# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.this.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.this.token
# }
#
# output "kubeconfig" {
#   value = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
# }
