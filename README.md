# PGP Decryption for Transfer Family

## Project Requirements 
### Created by setupEnvironment.sh script
- IAM Managed Workflow Execution Role 
- IAM Lambda Execution Role 
- Custom Lambda Layer including required binary/python package. 
### Created Manually via AWS Console
- Transfer Family Server
- Transfer Family Managed Workflow
- S3 Bucket
- Lambda Function for PGP Decryption


## Step-by-Step Instructions to Create Requirements

### Adding Private Key to Secrets Manager
- On the AWS Console, navigate to Secrets Manager. 
- Select "Store a new secret"
- Select "Other type of secret"
- Select "Plaintext"
- Delete the `{"":""}` 
- Paste in your Private Key
- Select "Next"
- Name your secret: PGP_PrivateKey
- Select "Next"
- Leave all options as default, select "Next"
- Select "Store"

### Creating an S3 Bucket (POSSIBLY OPTIONAL)
- NOTE: This step is only optional if you already have an S3 bucket configured that you'd like to use. 
- If not, you will need to follow these steps to create a new S3 bucket 
- Navigate to the S3 console within the AWS console
- Click "Create bucket"
- Name your bucket (Example: pgp-decrypted-files)
- Leave all options as default, unless you have specific requirements to do otherwise
- Scroll down to the bottom and select "Create bucket"

### CloudShell - Automated Creation of IAM Roles and Lambda Layer
- Open up CloudShell within your AWS account. 
- Run this command to clone this Git repository to access all the required files for this project: 
  
  `git clone https://github.com/aws-samples/pgp-decryption-for-transfer-family.git`
  
- Change into the new pgp-decryption-for-transfer-family directory: 
  
  `cd pgp-decryption-for-transfer-family/`

- Run this command to give the setupEnvironment.sh script executable permissions: 
  
  `chmod + x setupEnvironment.sh`
  
- Run this command to create the required IAM roles and Lambda layer:
  
  `./setupEnvironment.sh`
  

### Creating Transfer Family Server with Custom Identity Provider (OPTIONAL)
- NOTE: If you already have a Transfer Family server in place that you want to use, or if you don't want to use a custom identity provider, you can ignore this step. 
- However, this project does require that you have a Transfer Family server running within your AWS account, so if you don't currently have one, I'd recommend completing this step as it will create the Transfer Family server, custom identity provider, and all of the required IAM policies for you.  
- Refer to this link for detailed instructions on deploying a CloudFormation stack that will create a Transfer Family server, custom identity provider, and all the required IAM policies: https://aws.amazon.com/blogs/storage/enable-password-authentication-for-aws-transfer-family-using-aws-secrets-manager-updated/
- Short Summary of Steps Required: 
  - In CloudShell, run the following: 
    Download the CloudFormation stack using the link mentioned on the blog post linked above, at the time of creating this, the command is as follows: 
    
    `wget https://s3.amazonaws.com/aws-transfer-resources/custom-idp-templates/aws-transfer-custom-idp-secrets-manager-sourceip-protocol-support-apig.zip`

  - After downloading the zip, unzip it: 
    `unzip aws-transfer-custom-idp-secrets-manager-sourceip-protocol-support-apig.zip`
    
   - Run the following command:
      `sam deploy --guided`
      
    - Enter in a stack name (Example: TransferFamilyServer)
    - Press enter for all other options to leave them as default, refer to image for reference:
![image](https://user-images.githubusercontent.com/59907142/181582434-2df2a594-d905-4b69-973b-2fa8880a350d.png)


### Creating Transfer Family Server
- If you don't want to deploy the custom Transfer Family identity provider via CloudFormation mentioned in the above step, and don't have a currently up and running Transfer Family server, please refer to this link for instructions on how to create a new Transfer Family server: https://docs.aws.amazon.com/transfer/latest/userguide/getting-started.html
- If you deployed the CloudFormation stack mentioned in the step above, you can ignore this step. 


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



### Creating Transfer Family Managed Workflow
- Navigate to the Transfer Family console within the AWS console
- Select "Workflows"
- Select "Create Workflow"
- Provide a brief description of the workflow (Example: Automate PGP Decryption)
#### Nominal Steps
#### Step 1: Copy to Archive
- Under "Nominal steps", select "Add step"
  - Select "Copy file"
  - Name the step (Example: CopyToArchive)
  - Select destination bucket (Example: "pgp-decrypted-files")
  - For Destination key prefix, insert the following: "Archive/${transfer:UserName}/" 
  - Select "Next" and then "Create step"
  
#### Step 2: Tag as Archived  
- Under "Nominal steps", select "Add step" 
  - Select "Tag file"
  - Name the step (Example: TagAsArchived)
  - For file location, select "Tag the file created from previous step"
  - For Key enter: "Status"
  - For Value enter: "Archived"
  - Click "Next" and the "Create step"

#### Step 3: PGP Decryption
- Under "Nominal steps", select "Add step"
  - Select "Custom file-processing step"
  - Name the step (Example: PGPDecryption)
  - For file location, select "Apply custom processing to the original source file"
  - For target, select the Lambda function we created in earlier steps (Example: AutomatedPGPDecryption)
  - For timeout, leave as default (60 seconds)
  - Click "Next" and "Create step"

#### Step 4: Delete Originally Uploaded File
- Under "Nominal steps", select "Add step"
  - Select "Delete file"
  - Name the step (Example: DeleteOriginalFile)
  - For file location, select "Delete the original source file"
  - Click "Next" and "Create step"


#### Managed Workflow Exception Handlers

#### Step 1: Copy to Failed Prefix
- Under "Exception handlers - optional", select "Add step"
  - Select "Copy file"
  - Name the step (Example: CopyToFailedPrefix)
  - Select destination bucket (Example: "pgp-decrypted-files")
  - For Destination key prefix, insert the following: "FailedDecryption/${transfer:UserName}/" 
  - Select "Next" and then "Create step"

#### Step 2: Tag as Failed  
- Under "Exception handlers - optional", select "Add step"
  - Select "Tag file"
  - Name the step (Example: TagAsFailed)
  - For file location, select "Tag the file created from previous step"
  - For Key enter: "Status"
  - For Value enter: "Failed Decryption"
  - Click "Next" and the "Create step"

#### Step 3: Delete Originally Uploaded File
- Under "Exception handlers - optional", select "Add step"
  - Select "Delete file"
  - Name the step (Example: DeleteOriginalFile)
  - For file location, select "Delete the original source file"
  - Click "Next" and "Create step"


#### Final Step for Managed Workflow Creation
- Select "Create Workflow"


### Attach Managed Workflow to Transfer Family Server
- On the Transfer Family console, select "Servers"
- Select your desired Transfer Family server
- Under "Additional details", select "Edit"
- Select the newly created Workflow (Example: Automate PGP Decryption)
- Select the newly created Managed workflow execution role (Example: PGPDecryptionManagedWorkflowRole)
- Select "Save"


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

