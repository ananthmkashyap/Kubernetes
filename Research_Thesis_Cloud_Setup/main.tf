provider "kubernetes" {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "aws"
        # This requires the awscli to be installed locally where Terraform is executed
        args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
}

module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "~> 19.0"
    cluster_name = local.cluster_name
    cluster_version = "1.27"
    cluster_endpoint_public_access  = true

    cluster_addons = {
        coredns = {
            most_recent = true
    }
    kube-proxy = {
        most_recent = true
    }
    vpc-cni = {
        most_recent = true
    }
    }
    
    vpc_id = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnets

    tags = {
        Name = "Kashyaps-Cluster"
    }



    eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
    }

    eks_managed_node_groups = {
    green = {
        min_size     = 1
        max_size     = 10
        desired_size = 2

        instance_types = ["t2.micro"]
        capacity_type  = "SPOT"
    }
    }

    manage_aws_auth_configmap = true
    aws_auth_users = [
    {
        userarn  = "arn:aws:iam::352598743374:user/ananth_kashyap"
        username = "ananth"
        groups   = ["system:masters"]
    },
    ]
}

variable "region" {
    default = "eu-central-1"
}
data "aws_availability_zones" "available" {}

locals {
    cluster_name = "Kashyaps-Cluster"
}

module vpc {
    source = "terraform-aws-modules/vpc/aws"

    name = "Kashyap-EKS-VPC"
    cidr = "10.0.0.0/16"

    azs = data.aws_availability_zones.available.names
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets =  ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = true

    enable_dns_hostnames= true

tags = {
    "Name" = "Kashyap-EKS-VPC"
}
public_subnet_tags = {
    "Name" = "EKS-Public-Subnet"
}
private_subnet_tags = {
    "Name" = "EKS-Private-Subnet"
}
}

####

