provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "xtages_infra" {
  backend = "s3"
  config = {
    bucket = "xtages-tfstate"
    key    = "tfstate/us-east-1/production"
    region = "us-east-1"
  }
}

module "ecs" {
  cluster_name = "xtages-cluster-staging"
  source = "../"
  env = var.env
  aws_region = var.aws_region
  vpc_id = data.terraform_remote_state.xtages_infra.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.xtages_infra.outputs.private_subnets
  public_subnet_ids = data.terraform_remote_state.xtages_infra.outputs.public_subnets
}
