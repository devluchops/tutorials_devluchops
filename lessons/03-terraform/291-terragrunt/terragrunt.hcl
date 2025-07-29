terraform {
  source = "./"
}

inputs = {
  region      = "us-east-1"
  bucket_name = "my-terragrunt-bucket-example"
}
