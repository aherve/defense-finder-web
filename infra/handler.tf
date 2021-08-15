module "lambda_function_container_image" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "protein_handler_lambda"
  description   = ""

  create_package = false
  publish        = true

  image_uri    = "187971905951.dkr.ecr.eu-west-3.amazonaws.com/mdmparis/defense-finder:2.10"
  package_type = "Image"

  attach_policies    = true
  number_of_policies = 2
  policies = [
    aws_iam_policy.upload_to_results_policy.arn,
    aws_iam_policy.read_proteins_policy.arn
  ]

  allowed_triggers = {
    ProteinsS3 = {
      service    = "s3"
      source_arn = aws_s3_bucket.proteins_bucket.arn
    }
  }

  environment_variables = {
    results_bucket = aws_s3_bucket.results_bucket.id
  }

  timeout = 600
  memory_size = 8192
}

resource "aws_iam_role" "protein_handler_role" {
  name = "protein_handler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "upload_to_results_policy_attachment" {
  role       = aws_iam_role.protein_handler_role.name
  policy_arn = aws_iam_policy.upload_to_results_policy.arn
}
