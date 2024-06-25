# Table of Contents

1. [Prerequisites](#prerequisites)
    - [Reviewer: Technologies required and methods](#reviewer--technologies-required-and-methods)
    - [Create a Repository](#1-create-a-repository)
    - [Add Secrets to the Repository](#2-add-secrets-to-the-repository)
    - [Configure AWS Credentials Locally](#3-configure-aws-credentials-locally)
    - [Update Variables](#4-update-variables)
    - [Initialize Terraform](#5-initialize-terraform)
2. [Task 1 and 2: Litecoin Application Containerization and Automated Image Deployment](#task-1-and-2--litecoin-application-containerization-and-automated-image-deployment)
    - [Related Files](#related-files-litecoin)
    - [GitHub Actions Pipeline Overview](#github-actions-pipeline-overview-litecoin)
        - [Job 1: download_and_verify](#job-1--downloadandverify)
        - [Job 2: build_al2](#job-2--buildal2)
        - [Job 3: build_bb](#job-3--buildbb)
    - [Steps to Create and Deploy Docker Images](#steps-to-create-and-deploy-docker-images)
    - [Testing the Docker Images Locally](#testing-the-docker-images-locally)
    - [Image Size and Security](#image-size-and-security)
3. [Task 3: Terraform Infrastructure](#task-3--terraform-infrastructure)
    - [Related Files](#related-files-terraform)
    - [Terraform Modules and Configuration](#terraform-modules-and-configuration)
        - [S3 Bucket Configuration](#s3-bucket-configuration)
        - [IAM Configuration](#iam-configuration)
    - [Steps to Apply the Terraform Configuration](#steps-to-apply-the-terraform-configuration)
4. [Task 4: Lambda Function and Scripting](#task-4--lambda-function-and-scripting)
    - [GitHub Actions Pipeline Overview](#github-actions-pipeline-overview-lambda)
    - [Related Files](#related-files-lambda)
    - [Terraform Configuration Files](#terraform-configuration-files)
    - [Steps to Set Up the Lambda Function](#steps-to-set-up-the-lambda-function)
    - [Terraform Configuration](#terraform-configuration)
5. [Theory Question](#theory-question)
    - [How can you add libraries to a Python Lambda function if the library is not available by default?](#how-can-you-add-libraries-to-a-python-lambda-function-if-the-library-is-not-available-by-default)
        - [Small Libraries (Up to 50MB Unzipped)](#1-small-libraries-up-to-50mb-unzipped)
        - [Medium Libraries (Up to 250MB Unzipped)](#2-medium-libraries-up-to-250mb-unzipped)
        - [Moderate Libraries (Up to 250MB Unzipped Including Layers)](#3-moderate-libraries-up-to-250mb-unzipped-including-layers)
        - [Large Libraries (Over 250MB)](#4-large-libraries-over-250mb)
    - [AWS Lambda Quotas](#aws-lambda-quotas)
    - [Implementation Example](#implementation-example)
    - [Summary](#summary)

## Prerequisites

### Reviewer: Technologies required and methods

Before starting, ensure you have the following:

- Docker installed on your local machine.
- An AWS account with access to create and manage ECR repositories.
- GitHub account to access and collaborate on repositories.
- Terraform v1.8.5 installed.

To facilitate the review of the CI/CD pipelines, please follow these steps:

### 1. Create a Repository

- **Option 1: Fork the Repository**:
    - Fork the original repository to your GitHub account.

- **Option 2: Clone and Create a New Private Repository**:
    - Clone the repository locally:
      ```sh
      git clone <repository-url>
      ```
    - Create a new private repository in your GitHub account.
    - Push the cloned repository to the new private repository:
      ```sh
      cd <cloned-repository>
      git remote set-url origin <new-repository-url>
      git push -u origin master
      ```

### 2. Add Secrets to the Repository

- Add necessary secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `GH_TOKEN`, etc.) to the forked or new repository
  under `Settings` > `Secrets and variables` > `Actions`.

### 3. Configure AWS Credentials Locally

- **Option 1: Add Credentials to File and Export Profile**:
    - Add your AWS credentials to your local `~/.aws/credentials` file:
      ```sh
      [example]
      aws_access_key_id = YOUR_AWS_ACCESS_KEY_ID
      aws_secret_access_key = YOUR_AWS_SECRET_ACCESS_KEY
      ```
    - Export the AWS profile to your environment:
      ```sh
      export AWS_PROFILE=example
      ```

- **Option 2: Directly Export AWS Credentials**:
    - Export the AWS credentials to your environment:
      ```sh
      export AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
      export AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
      ```

### 4. Update Variables

- Update `allowed_account_ids` in `providers.tf`:
  ```yaml
  terraform/dev/us-east-1/providers.tf
  ```

- Update `account_id` and `trusted_account_id` in `locals.tf`:
  ```yaml
  terraform/dev/us-east-1/locals.tf
  ```

- Update `AWS_ACCOUNT_ID` in GitHub Actions workflows `litecoin-images.yml` and `s3-events-lambda.yml`:
  ```yaml
  .github/workflows/litecoin-images.yml
  
  .github/workflows/s3-events-lambda.yml
  ```

### 5. Initialize Terraform

- Navigate to the Terraform directory and run:

 ```sh
  cd terraform/dev/us-east-1
  terraform init
 ```

## Task 1 and 2: Litecoin Application Containerization and Automated Image Deployment

**Objective:**  
These tasks involve containerizing a Litecoin application using Docker and automating the image deployment process with
GitHub Actions. The aim is to create two Docker images (one with Amazon Linux 2 and another with BusyBox), push these
images to Amazon ECR, and ensure they are secure and optimized for size and performance.

### Related Files Litecoin

- [Dockerfile.al2](litecoin%2FDockerfile.al2)
- [Dockerfile.bb](litecoin%2FDockerfile.bb)
- [Makefile](litecoin%2FMakefile)
- [litecoin-images.yml](.github%2Fworkflows%2Flitecoin-images.yml)

### GitHub Actions Pipeline Overview Litecoin

**Pipeline File Reference**: [s3-events-lambda.yml](.github%2Fworkflows%2Fs3-events-lambda.yml)

#### Job 1: `download_and_verify`

- **Steps**:
    1. **Checkout Code**: Checks out the repository code.
    2. **Download and Verify Litecoin Binary**: Downloads the Litecoin binary and its checksum, verifies the binary,
       extracts it and strips it.
    3. **Upload litecoind binary**: Uploads the litecoind binary as an artifact so the next two jobs run in parallel,
       both using the binary artifact.

#### Job 2: `build_al2`

- **Steps**:
    1. **Checkout Code**: Checks out the repository code.
    2. **Download litecoind Binary**: Downloads the \`litecoind\` binary artifact created in the previous job.
    3. **Configure AWS Credentials**: Configures AWS credentials from GitHub Secrets.
    4. **Login to ECR**: Authenticates Docker to Amazon ECR.
    5. **Build Docker Image (Amazon Linux 2)**: Builds the Docker image using the \`Dockerfile.al2\` file.
    6. **Run Trivy Scan on AL2 Image**: Runs a security scan on the built Docker image using Trivy.
    7. **Tag and Push Amazon Linux 2 Docker Image to ECR**: Tags and pushes the Docker image to the Amazon ECR
       repository.

#### Job 3: `build_bb`

- **Steps**:
    1. **Checkout Code**: Checks out the repository code.
    2. **Download litecoind Binary**: Downloads the \`litecoind\` binary artifact created in the previous job.
    3. **Configure AWS Credentials**: Configures AWS credentials from GitHub Secrets.
    4. **Login to ECR**: Authenticates Docker to Amazon ECR.
    5. **Build Docker Image (BusyBox)**: Builds the Docker image using the \`Dockerfile.bb\` file.
    6. **Tag and Push BusyBox Docker Image to ECR**: Tags and pushes the Docker image to the Amazon ECR repository.

### Steps to Create and Deploy Docker Images

1. **Create Required ECR Repository for the Images**:
    - Run the following Terraform command to create the necessary ECR repository:
      ```sh
      terraform apply --target module.litecoin_app_ecr_repo
      ```

2. **Trigger the GitHub Actions Pipeline**:
    - Create a no-op PR (e.g., add an empty line) in any file in the [litecoin](litecoin) folder.
    - Merge the PR to master to trigger the [litecoin-images.yml](.github%2Fworkflows%2Flitecoin-images.yml) workflow.
    - Follow the pipeline progress in the GitHub Actions tab.

### Testing the Docker Images Locally

To test the Docker images locally, follow these steps:

1. **Authenticate to ECR**:
    - Use the AWS CLI to authenticate Docker to your Amazon ECR registry:
      ```sh
      aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
      ```

2. **Pull and Run the Docker Images**:
    - Pull and run the BusyBox image:
      ```sh
      docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/project-litecoin:bb-0.21.3
      docker run -it --rm <account-id>.dkr.ecr.us-east-1.amazonaws.com/project-litecoin:bb-0.21.3
      ```
    - Pull and run the Amazon Linux 2 image:
      ```sh
      docker pull <account-id>.dkr.ecr.us-east-1.amazonaws.com/project-litecoin:al2-0.21.3
      docker run -it --rm <account-id>.dkr.ecr.us-east-1.amazonaws.com/project-litecoin:al2-0.21.3
      ```

### Image Size and Security

- **Amazon Linux 2 Image**:
    - The image is less than 80 MB and focuses on security.
    - Trivy scan results for the Amazon Linux 2 image:
        - Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

- **BusyBox Image**:
    - The image is 10 MB and focuses on minimal size.
    - Note: The BusyBox image is not compatible with security scanning tools like Trivy due to its minimal OS structure.

## Task 3: Terraform Infrastructure

**Objective:**  
This task focuses on using Terraform to set up AWS infrastructure. The goal is to create an S3 bucket with lifecycle
policies, IAM roles and policies, and other necessary configurations to support the application. This ensures that the
infrastructure is managed as code, enabling consistency, repeatability, and scalability.

### Related Files Terraform

- [iam.tf](terraform%2Fdev%2Fus-east-1%2Fiam.tf)
- [s3.tf](terraform%2Fdev%2Fus-east-1%2Fs3.tf)
- [aws-s3-bucket](terraform%2Fmodules%2Faws-s3-bucket)

### Terraform Modules and Configuration

#### S3 Bucket Configuration

The S3 bucket configuration includes:

- Creating the bucket.
- Setting lifecycle rules to remove files older than a specified number of days.
- Enabling versioning for the S3 bucket.
- Enforcing server-side encryption.
- Ensuring bucket owner full control.
- Blocking public access.
- Defining and applying a policy document for cross-account read access if a trusted account ID is provided.

#### IAM Configuration

The IAM configuration includes:

- Defining an IAM group for the project.
- Creating an IAM user and adding the user to the group.
- Creating an IAM policy that grants S3 access permissions (put, get, delete, list).
- Attaching the S3 access policy to the IAM group.
- Creating an IAM role for the Lambda function with an assume role policy for Lambda.
- Attaching the S3 access policy to the Lambda role.

### Steps to Apply the Terraform Configuration

Since the Terraform configurations are dependent on the Lambda image being available in the ECR repository,
the entire Terraform configuration will be applied in the next task.

## Task 4: Lambda Function and Scripting

**Objective:**  
The objective of this task is to develop a Lambda function triggered by S3 events to move files within an S3 bucket.
This involves creating the Lambda function, setting up the necessary AWS resources like SQS and IAM roles via Terraform,
and automating the deployment process using Docker and GitHub Actions.

### Related Files Lambda

- [s3_events.py](lambda-s3-events%2Fs3_events.py)
- [Dockerfile](lambda-s3-events%2FDockerfile)
- [Makefile](lambda-s3-events%2FMakefile)
- [s3-events-lambda.yml](.github%2Fworkflows%2Fs3-events-lambda.yml)

### Terraform Configuration Files

- [lambda.tf](terraform%2Fdev%2Fus-east-1%2Flambda.tf)
- [sqs.tf](terraform%2Fdev%2Fus-east-1%2Fsqs.tf)
- [iam.tf](terraform%2Fdev%2Fus-east-1%2Fiam.tf)
- [aws-lambda](terraform%2Fmodules%2Faws-lambda)

### GitHub Actions Pipeline Overview Lambda

**Pipeline File Reference**: [litecoin-images.yml](.github%2Fworkflows%2Flitecoin-images.yml)

#### Job: `build_deploy_lambda`

- **Steps**:
    1. **Checkout Code**: Checks out the repository code.
    2. **Configure AWS Credentials**: Configures AWS credentials from GitHub Secrets.
    3. **Install GitVersion**: Installs GitVersion to manage semantic versioning.
    4. **Execute GitVersion**: Runs GitVersion to determine the version.
    5. **Set GitVersion Output as Environment Variable**: Sets the GitVersion output as an environment variable.
    6. **Build Docker Image**: Builds the Docker image using the `Dockerfile`.
    7. **Run Trivy Scan on Docker Image**: Runs a security scan on the built Docker image using Trivy.
    8. **Login to ECR**: Authenticates Docker to Amazon ECR.
    9. **Tag and Push Docker Image to ECR**: Tags and pushes the Docker image to the Amazon ECR repository.
    10. **Create GitHub Release**: Creates a GitHub release for the new image version.

### Steps to Set Up the Lambda Function

**Trigger the GitHub Actions Pipeline**:

1. Run the following Terraform command to create the necessary ECR repository:
      ```sh
      terraform apply --target module.s3_events_lambda_ecr_repo
      ```
2. 
    - Create a no-op PR (e.g., add an empty line) in any file in the [lambda-s3-events](lambda-s3-events) folder.
    - Merge the PR to master to trigger the [s3-events-lambda.yml](.github%2Fworkflows%2Fs3-events-lambda.yml) workflow.
    - Follow the pipeline progress in the GitHub Actions tab.
    - A new lambda image should be built and pushed to the ecr repository
    - Note the image version and use in the following step

**Apply the Terraform Configuration**:

1. Update the local tag variable in [lambda.tf](terraform%2Fdev%2Fus-east-1%2Flambda.tf) so the lambda can use the
   new image:

2. Apply the rest of Terraform configuration:
      ```sh
      terraform apply
      ```

**Upload a file to the S3 bucket to trigger the lambda**:

```sh
echo "testing" > test.txt
aws s3 cp test.txt s3://project-events-bucket/source/test.txt
```

**Wait few minutes and check logs in lambda console**:

### Terraform Configuration

1. **Defining the Lambda Function**:
    - Configure the Lambda function with necessary environment variables.
    - Assign an IAM role to the Lambda function with a trust policy allowing the Lambda service to assume the role.

2. **Creating SQS Queues**:
    - Define a main SQS queue for receiving notifications from the S3 bucket when new objects are created.
    - Create a Dead Letter Queue (DLQ) to store messages that could not be processed successfully.
    - Set up the redrive policy to send messages to the DLQ after a specified number of receive attempts.

3. **Mapping SQS Queue to Lambda**:
    - Map the main SQS queue to the Lambda function, so it can process messages in batches.

4. **Configuring IAM Policies**:
    - Attach the S3 access policy to the Lambda role to grant necessary permissions.
    - Assign additional IAM policies for logging and SQS access:
        - **Logging Policy**: Grants permissions to create and manage CloudWatch log groups, streams, and events.
        - **SQS Policy**: Allows the Lambda function to receive and delete messages from the SQS queue.

5. **Configuring S3 Bucket Notifications**:
    - Set up S3 bucket notifications to send events to the SQS queue when new objects are created in the bucket.

## Theory Question

### How can you add libraries to a Python Lambda function if the library is not available by default?

When you need to add libraries to a Python Lambda function that are not available by default, you have several options
depending on the size of the libraries:

#### 1. **Small Libraries (Up to 50MB Unzipped)**

- **Direct Upload**:
    - **Description**: Directly upload the deployment package (ZIP file) to AWS Lambda.
    - **Use Case**: Suitable for small functions with minimal dependencies.
    - **Limitations**: The zipped package must be less than 50MB.

#### 2. **Medium Libraries (Up to 250MB Unzipped)**

- **S3 Deployment Package**:
    - **Description**: Upload the deployment package to an S3 bucket and specify the S3 location in AWS Lambda.
    - **Use Case**: Suitable for larger functions that exceed the direct upload limit.
    - **Limitations**: The unzipped package must be less than 250MB.
    - **Documentation**: [AWS Lambda Deployment Packages](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-package.html#deployment-package-s3)

#### 3. **Moderate Libraries (Up to 250MB Unzipped Including Layers)**

- **Lambda Layers**:
    - **Description**: Create a Lambda Layer to include shared libraries and attach it to your function.
    - **Use Case**: Allows sharing common dependencies across multiple functions.
    - **Limitations**: The combined uncompressed size of the function and all layers must not exceed 250MB.
    - **Documentation**: [AWS Lambda Layers Documentation](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html)

#### 4. **Large Libraries (Over 250MB)**

- **Docker Images**:
    - **Description**: Package the Lambda function as a Docker image and store it in a container registry like Amazon ECR or Docker Hub.
    - **Use Case**: Suitable for functions with very large dependencies or complex setups.
    - **Limitations**: The image size can be up to 10GB.
    - **Documentation**: [AWS Lambda Container Images](https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html)

### AWS Lambda Quotas

- **Concurrent Executions**: 1,000 (can be increased)
- **Storage for Uploaded Functions and Layers**: 75 GB (can be increased)
- **Deployment Package Size**: 50 MB (zipped, direct upload), 250 MB (unzipped)
- **Container Image Code Package Size**: 10 GB
- **Layers**: 5 layers
- **Temporary Storage (`/tmp` directory)**: 512 MB to 10,240 MB
- **Memory Allocation**: 128 MB to 10,240 MB
- **Function Timeout**: 900 seconds (15 minutes)
- **Environment Variables**: 4 KB (aggregate)

For more details, visit the [AWS Lambda Quotas Documentation](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html).

### Implementation Example

For detailed implementation, see the [lambda-s3-events](lambda-s3-events) directory, which includes:

- **s3_events.py**: The Python Lambda function code.
- **Dockerfile**: The Dockerfile to build the Lambda function as a Docker image.
- **requirements.txt**: List of Python dependencies for the Lambda function.
- **Makefile**: Commands to build and clean the Docker image.
- **s3-events-lambda.yml**: GitHub Actions pipeline for automating the build and deployment process.

### Summary

When adding external libraries to a Python Lambda function, consider the size of the dependencies and choose the
appropriate method: S3 packaging, Lambda Layers, or Docker images. Each method has its limits and best use cases,
with Docker images providing the most flexibility for larger dependencies.
