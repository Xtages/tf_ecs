# ecs ec2 role
resource "aws_iam_role" "ecs_ec2_role" {
  name_prefix        = "ecs_ec2_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "ecs_ec2_role" {
  name_prefix = "ecs_ec2_role"
  role        = aws_iam_role.ecs_ec2_role.name
}

resource "aws_iam_role_policy" "ecs_ec2_role_policy" {
  name_prefix = "ecs_ec2_role_policy"
  role        = aws_iam_role.ecs_ec2_role.id
  policy = templatefile("${path.module}/policies/ecs_ec2_role_policy.json",{})
}

# ecs service role
resource "aws_iam_role" "ecs_service_role" {
  name_prefix        = "ecs_service_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

variable "iam_policy_arn_for_ecs_service" {
  description = "IAM policies to attach to ECS service role"
  default = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
  ]
  type = list(string)
}

resource "aws_iam_role_policy_attachment" "ecs_service_attach" {
  role       = aws_iam_role.ecs_service_role.name
  count      = length(var.iam_policy_arn_for_ecs_service)
  policy_arn = var.iam_policy_arn_for_ecs_service[count.index]
}

