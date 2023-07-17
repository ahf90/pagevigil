# PageVigil
PageVigil screenshots your webpages and stores the screenshots in S3.

## How does it work?
A Lambda runs minutely to screenshot the pages stored in config.yml.
It stores those screenshots in an S3 bucket.

The Lambda uses a container image. The image is a [public image](https://gallery.ecr.aws/m5e2w3a9/pagevigil) generated from this repository.  
Unfortunately, Lambdas can only use images in private ECR repositories.
Therefore, this creates a private ECR repo and copies the latest version to your private ECR repo.

## Getting Started
All the Terraform required to set this up is in the `terraform` folder of this repository.
All you need to do is update your local `config.yml` with your desired webpages.
You must have both Terraform and Docker running the machine running the Terraform

1. Clone or fork the repository
2. Update `config.yml` with the list of webpages you want to follow
3. Update `terraform/terraform.tfvars` with
   1. The email to be used for errors (`errors_email`)
   2. The frequency at which you want to screenshot the images (`frequency`)
4. Plan and apply the Terraform

