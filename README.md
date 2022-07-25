# PGP Decryption for Transfer Family

## Configuring your AWS Environment


### CloudShell - Automated Creation of IAM Policies and Lambda Layer
- Open up CloudShell within your AWS account. 
- Run this command to download the setupEnvironment.sh script and the required IAM policies: 
  
  `wget https://github.com/aws-samples/pgp-decryption-for-transfer-family/blob/main/setupEnvironment.sh https://github.com/aws-samples/pgp-decryption-for-transfer-family/blob/main/IAM_Policies.zip`
  
- Run this command to create the required IAM policies and Lambda layer:
  
  `./setupEnvironment.sh`
  
### IAM - Manual Creation of Two Required IAM Roles using AWS Console
- After running the setupEnvironment.sh script mentioned above, navigate to IAM -> Roles within the AWS Management Console. 

_Transfer Family Managed Workflow Role_
- Click "Create Role" 
- Select "AWS Service" and then search and select "Transfer"
- Click "Next"
- Select the following permissions policies:
  - PGPDecryptionManagedWorkflowPolicy
  - PGPDecryptionTransferFamilyPolicy
- Click "Next"
- Name the role (Example: PGPDecryptionManagedWorkflowRole)
- Click "Create Role"

_Lambda Function Execution Role_
- Click "Create Role"
- Select "AWS Service" and then select "Lambda"
- Click "Next"
- Select the following permissions policies:
  - PGPDecryptionCloudWatchPolicy
  - PGPDecryptionS3Policy
  - PGPDecryptionSecretsManagerPolicy
  - PGPDecryptionTransferFamilyPolicy
- Click "Next"
- Name the role (Example: PGPDecryptionLambdaExecutionRole)
- Click "Create Role"


### Deploying Custom Transfer Family Identity Provider (OPTIONAL)
- NOTE: If you already have a Transfer Family server in place that you want to use, or if you don't want to use a custom IDP, you can ignore this step. However, this project does require that you have a Transfer Family server running within your AWS account, so if you don't currently have one, I'd recommend deploying this CloudFormation stack as it will create the Transfer Family server + all the required IAM policies for you.  
- Refer to this link for detailed instructions on deploying the Custom Transfer Family Identity Provider: [https://aws.amazon.com/blogs/storage/enable-password-authentication-for-aws-transfer-family-using-aws-secrets-manager-updated/](url)


### Creating the Lambda Function
- On the AWS Console, navigate to Lambda -> Functions
- Click "Create function"
- Select "Author from scratch"
- Name your Lambda function (Example: AutomatedPGPDecryption)
- Select "Python 3.8" as the Runtime
- Select "x86_64" as the Architecture
- Select "Change default execution role"
  - Select "Use an existing role"
  - Search "PGPDecryptionLambdaExecutionRole" and select it
- Click "Create Function"
- After creating the function, paste in the Python code from the lambdaSource.py file hosted on this GitHub.
- Click "Deploy" to save your changes

#### Attaching Layer to Lambda Function
- Scroll to the bottom of your Lambda function and select "Add a layer"
- Select "Custom layers"
- Choose "python-gnupg" as the layer
- Select whichever version is present and click "Add"


#### Editing Default Lambda Timeout
- Within your Lambda function console, select "Configuration" and then "General Configuration"
- Click "Edit"
- Change the timeout time from 3 seconds -> 15 seconds


### S3 - Manually Creating an S3 Bucket (POSSIBLY OPTIONAL)
- NOTE: This step is only optional if you already have an S3 bucket configured that you'd like to use. 
- If not, you will need to follow these steps to create a new S3 bucket 
- Navigate to the S3 console within the AWS console
- Click "Create bucket"
- Name your bucket (Example: pgp-decrypted-files)
- Leave all options as default, unless you have specific requirements to do otherwise
- Scroll down to the bottom and select "Create bucket"



### Transfer Family - Manually Creating Transfer Family Managed Workflow
- Navigate to the Transfer Family console within the AWS console
- Select "Workflows"
- Select "Create Workflow"
- Provide a brief description of the workflow (Example: Automate PGP Decryption)









## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

