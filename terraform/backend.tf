terraform {
  backend "gcs" {
    bucket = "YOUR_PROJECT_ID-terraform-state" # Replace with your actual project ID
    prefix = "prod/terraform.tfstate"
  }
}
