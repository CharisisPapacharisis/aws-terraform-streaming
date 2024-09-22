# Streaming Project with AWS & Terraform

## Overview 

This project focuses on extracting cryptocurrency spot prices for three main crypto (Bitcoin, Ethereum, XRP), as a `streaming` data flow, transforming that input, and loading that in the data lake, where it is easy to query.

The tech stack is mainly AWS & Terraform.

The flow is as follows: 
- The *coinbase_api_call* **lambda** function performs GET requests to the Coinbase API, and retrieves the spot prices. We can schedule it to run every minute via Amazon EventBridge.
- The lambda function writes the data in a **Kinesis data stream**, which is then written into **Kinesis firehose**. 
- Firehose drops this data in the form of json files in a landing S3 bucket. 
- **AWS Glue** reads this data from the Data Catalog, and performs cleaning & transformations, sending eventually the output to a staging bucket. 
- We can query the final dataset from the staging **S3** bucket via **Athena**, or to expose it for API GET requests via an **AWS API Gateway**, thanks to the *lambda_query_athena* function that operates as the backend of API Gateway. 
- We also send out notifications via **SNS** when a new file lands in the landing S3 bucket, and if a new BTC price is detected above a certain threshold. This is managed by the *lambda_triggering_sns* function.


The **Glue ETL** script runs on *Spark*. It loads data from the source bucket, and adds new `partition columns` extracting the `year`, `month`, `day`, and `hour` from the timestamp_utc column. It also adds a date column by converting the first 10 characters of the timestamp_utc into a *date format*, creates a column with proper *timestamp format* and does *casting*. Then it writes the new dataframe to the destination bucket, in *Parquet* format, and partitioned by crypto type, year, month, day, and hour, improving this way the query performance and storage efficiency. 

The *enableUpdateCatalog=True* option ensures that the Glue Data Catalog is updated with the new partitions, so Athena can pick them up in future queries. The job is committed with `job.commit()` to indicate that all processing steps have been completed successfully. Note that by configuring the *job-bookmarks* as *Enabled*, we allow incremental processing. This ensures that the job only processes new or updated data since the last run. 


In terms of the **Simple Notification Service (SNS)**, we create:
- an *SNS topic*, which is a channel to which messages can be published. 
- a *subscription* for sending email notifications, that will notify a specific endpoint (an email address, in this case) when a message is published to the SNS topic. 
Then, we can add our email as endpoint, either in the Terraform file, or by using the AWS UI. AWS SNS will send a confirmation email to the email address we provided. We need to confirm the subscription by clicking on the link in that email, in order to start receiving notifications.


The **API Gateway** defines a REST API, with an endpoint URL that users can call, via the GET method. Our definition in the Terraform file ensures that an API key must be included in the request. The API Gateway is connected to a backend AWS Lambda function, *query_athena_currencies*. The API Gateway will proxy the incoming GET requests to the Lambda function using the HTTP POST method. There is also a usage plan defined for the ones using the API key, that controls the rate limits and quotas (throttle settings: rate_limit, burst_limit).


## SAM CLI

We can use the **AWS SAM (Serverless Application Model)** CLI for local development and testing. It provides an environment for quick testing and iteration of lambda functions, without the need to upload and test the code on the AWS UI interface.

**Prerequisites**
- Install AWS SAM CLI: Follow AWS SAM CLI installation guide.
- Install Docker: SAM CLI uses Docker to simulate Lambda environments locally.
- Set up AWS CLI: Configure your AWS credentials if you plan to deploy the Lambda function to AWS.

First, initialize a new SAM application:
```bash
sam init
```
After selecting your template to use, runtime, and project name, you get a folder structure in your SAM project, similar to this:

```bash
my-sam-app/
├── coinbase_api_call/
│   ├── app.py              # Lambda function code
│   ├── __init__.py
├── events/
│   └── event.json          # Sample input event for testing
├── template.yaml           # SAM template defining Lambda and resources
└── tests/                  # Test cases
    ├── unit/
    └── integration/
```

Modify the `coinbase_api_call/app.py` file to write your Lambda logic.

The `template.yaml` file is the SAM template where you define the Lambda function and any associated AWS resources (e.g. timeout, memory size). You can adjust that as per your preference.

After you are done with developing your code in app.py, you can build it. This processes the template and prepares the application for deployment or local testing. The `sam build` command compiles the application and organizes the Lambda code into an `.aws-sam` directory.
```bash
sam build
```

You can test the Lambda function locally using SAM CLI to simulate the AWS environment. You can invoke the function directly
(you can find the function name-to-use, under the `.aws-sam > build.toml` file, along with other function metadata):
```bash
sam local invoke CoinbaseApiCall
```

Once you have tested your function locally, you can deploy it to AWS.
```bash
sam deploy --guided
```

You can follow the prompts appearing next, to specify the deployment parameters, such as AWS Region, Stack name. 
Once deployed, you can test the function directly in AWS.

To update the function later, you can modify the code in app.py, and build + deploy again:
```bash
sam build && sam deploy --guided
```

## Terraform 
Once we are content with the development & testing of our lambda functions, we can use **Terraform** to deploy them in AWS, along with any other components present in our solution, such as kinesis, S3, glue, sns, api gateway. Using Infrastructure as Code (IaC) provides various benefits, such as:
- `Version Control`: Your infrastructure configurations can be stored in version control systems (like Git), allowing you to track changes, roll back to previous versions, and collaborate with others.
- `Separate Environments`: The dev and prod directories allow you to maintain separate configurations, reducing the risk of accidentally affecting production while testing in development.
- `Reusable Modules`: By encapsulating related resources in modules, you can reuse the same code across different environments, promoting DRY (Don't Repeat Yourself) principles.
- `State Management`: Terraform keeps track of your infrastructure state, allowing you to see what resources are currently deployed and making it easier to manage changes over time.
- `Automated Dependency Resolution`: Terraform understands the relationships between resources and automatically manages dependencies, ensuring that resources are created or destroyed in the correct order.
- `Integration with CI/CD`: Terraform integrates well with CI/CD pipelines, allowing for automated infrastructure deployments.

### Notes
As the different components interact with each other, we need to ensure that each one is assigned a relevant IAM Role, which has the right IAM Policies attached to it, which allow for the relevant actions. For example:

 The `coinbase_api_call` function needs:
 -  access to Kinesis, in order to write its output to a Kinesis data stream
 -  access to the AWS Secret Manager, in order to retrieve the coinbase API key
 -  access to Cloudwatch logs, in order to write logs there
 
The `lambda_triggering_sns` function needs:
-  access to the landing bucket in order to check the BTC value
-  access to the sns queue, in order to publish a message there, in case the value is above a threshold
-  access to Cloudwatch logs, in order to write logs there

The `query_athena_currency` function needs:
-  access to Athena, which enables the lambda function to query S3 buckets
-  access to the landing S3 bucket, in order to read files
-  access to Cloudwatch logs, in order to write logs there
-  access to the S3 bucket where the query results of Athena is stored

The `Kinesis Firehose` needs:
-  access to Glue data catalog/tables 
-  S3 permissions in order to interact with an S3 bucket for storing data
-  Cloudwatch log permisssions
-  access to a Kinesis data stream

The `Glue job` needs: 
-  an S3 bucket where the Glue ETL script is stored, and access to it
-  access to the S3 landing bucket, where data is read from, as well as the S3 staging bucket, where data is dropped after the transformation

The `API Gateway` needs: 
-  Permission to invoke the backend lambda function

All this is managed via the Terraform files.


Specifically for the `coinbase_api_call`, which has several dependencies: We can create a "resource" in Terraform (based on `null_resource`) which executes a local command to install Python dependencies required by the Lambda function, with `pip3 install`, and is triggered only when the `requirements.txt` file changes (based on its SHA1 hash). 

Then, the folder that contains the lambda code (`src_coinbase_lambda` directory) is zipped together with the installed dependencies. Note: We have splitted the functionalities of reading a secret from the AWS Secret Manager, as well as writing data to Kinesis Data Stream, in separate functions/files under the same folder. These files are also zipped together in this process. The zip file will be used to deploy the lambda function to AWS. See `"aws_lambda_function" "coinbase_request"` resource for that. This part (zipping and deploying) is applied also for the other lambda functions.


The Terraform code for `Glue` points to the python script that we use for the transformations (`ETL_script.py`). This script is located relative to the current Terraform module, and it will be uploaded to an S3 bucket to be used by the Glue job. The Glue job depends on the successful upload of the ETL script, ensuring the script is in the S3 bucket before the job starts. Access logging is enabled in Terraform for the staging bucket, with logs being sent to another bucket.

This Terraform code doesn't explicitly mention the IAM policy that grants the AWS Glue job access to read from and write to the S3 buckets involved in the ETL process. The IAM permissions can be handled through the IAM Role that is attached to the Glue job. A policy should be attached to the role, granting:
- Read access to the source S3 bucket (e.g., `GetObject, ListBucket`).
- Write access to the staging S3 bucket (e.g., `PutObject`).

### Structure
This Terraform project structure is organized into **environments** ( dev and prod) and **modules** (e.g. glue, api_gateway, and lambda_coinbase). 

**Environments**:
Each environment folder contains its own configuration files. This allows you to maintain separate settings, resources, and state for development and production environments.
Each environment can have its own terraform.tfvars file for variable values specific to that environment (e.g. resource sizes, API endpoints).

**Modules**:
The modules directory contains reusable Terraform modules. Each module encapsulates related resources, making it easier to manage, maintain, and reuse code.
For example, the *api_gateway* module could handle all resources related to setting up an API Gateway, while the *glue* module could manage AWS Glue jobs.


**Benefits of This Structure**
- `Separation of Concerns`: You can easily manage different configurations, which helps prevent accidental changes in production while testing in development. You can apply, plan, and destroy resources in each environment independently, making it safer to manage infrastructure.
- `Reusability`: Modules promote code reuse. You can define your infrastructure once in a module and instantiate it in multiple environments, which reduces duplication and the chance of errors.
- `Maintainability`: This structure makes it clear where to find configurations and which resources belong to which environment.


### How to run

As a prerequisite, Terraform needs a **state**. 

In the provider.tf file, we can see that the Terraform state is configured to be stored *remotely in an S3 bucket*, different for dev and prod. You need to make sure that the bucket exists in your region. If it doesn't exist, create it via the AWS Management Console or CLI:
```bash
aws s3 mb s3://[bucketname] --region [regionname]
```

You can also add versioning to the S3 bucket to maintain a history of state file changes:
```bash
aws s3api put-bucket-versioning --bucket [bucketname] --versioning-configuration Status=Enabled
```

The AWS user or role that is running Terraform needs proper permissions to access the S3 bucket for reading and writing state files. Ensure that your IAM role or user has the following permissions:

```bash
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject",
    "s3:ListBucket"
  ],
  "Resource": [
    "arn:aws:s3:::[bucketname]",
    "arn:aws:s3:::[bucketname]/*"
  ]
}
```

Then, to run the Terraform code **manually** in both environments, follow these steps:

1. Navigate to the Environment Directory:

For development:
```bash
cd environments/dev
```
For production:
```bash
cd environments/prod
```

2. Initialize Terraform:

This command sets up the Terraform environment, downloading necessary providers, and setting up the S3 backend for storing state remotely.

Terraform will prompt you to confirm if you'd like to migrate any existing local state to the new remote S3 backend (if a local state exists).
```bash
terraform init
```

3. Plan the Deployment:

This command generates an execution plan, allowing you to review what Terraform will change:
```bash
terraform plan
```
You can specify the `terraform.tfvars` file automatically by including it in the command:
```bash
terraform plan -var-file=terraform.tfvars
```

4. Apply the Changes:

This command creates or updates the resources defined in your Terraform files:
```bash
terraform apply
```

Again, you can specify the `terraform.tfvars` file if needed:
```bash
terraform apply -var-file=terraform.tfvars
```

5. Repeat for Production:

Follow the same steps in the prod directory to apply your production configurations.


## GitHub Actions CI/CD pipeline
Instead of doing manually all those steps, I created a `GitHub Actions CI/CD pipeline` that automates the deployment of the Terraform infrastructure to both development and production environments. 

The workflow can be triggered manually from the GitHub Actions tab (`workflow_dispatch`), allowing for flexible deployments.

It consists of two main jobs: `DeployToDev` and `DeployToProd`.

1. **DeployToDev**
- Environment: This job runs on ubuntu-latest and focuses on deploying to the development environment.
- `Working Directory`: It sets the working directory to environments/dev.

- Steps: 
    - Git Clone: Checks out the repository code, making it available for subsequent steps.
    - Set Up Python: Configures Python 3.9, which might be needed for scripts or tools used in the deployment.
    - Configure AWS Credentials: Uses a specific IAM role to configure AWS credentials, allowing the workflow to interact with AWS services.
    - Dump Context: Outputs GitHub and job context for debugging or logging purposes.
    - Set Up Terraform: Installs Terraform using a GitHub Action.
    - Terraform Format Check: Runs `terraform fmt -check` to ensure the Terraform code is properly formatted.
    - Terraform Init: Initializes the Terraform configuration, setting up the backend and preparing for further commands.
    - Terraform Plan: Creates a plan for what Terraform will do, showing changes without applying them.
    - Terraform Apply: Applies the changes automatically without requiring confirmation.

2. **DeployToProd**
- Similar as above, but for Prod.
- `Dependency`: It depends on the successful completion of the DeployToDev job (`needs: DeployToDev`).

To run the pipeline:

Push changes to your GitHub repository.

Go to the `Actions` tab in your repository.

Select the `test_flow` workflow and click the "Run workflow" button to trigger it manually.