# PGP Decryption for Transfer Family

## Project Requirements 
### Created by setupEnvironment.sh script
- Custom Lambda Layer including required binary/python package.

### Created via CloudFormation Stack
Setup Environment Stack - REQUIRED 
- IAM Roles, Lambda Function, and S3 Bucket.

Custom Transfer Family Identity Provider Stack - OPTIONAL
- Transfer Family Server and Custom Lambda Identity Provider.

### Created Manually via AWS Console
- PGP Private Key Secret
- Transfer Family Server
- Transfer Family Managed Workflow


## Step-by-Step Instructions to Create Requirements

### CloudShell - Automated Creation of Lambda Layer
- Open up CloudShell within your AWS account. 
- Run this command to clone this Git repository to access all the required files for this project: 
  
  `git clone https://github.com/aws-samples/pgp-decryption-for-transfer-family.git`
  
- Change into the new pgp-decryption-for-transfer-family directory: 
  
  `cd pgp-decryption-for-transfer-family/`

- Run this command to give the setupEnvironment.sh script executable permissions: 
  
  `chmod + x setupEnvironment.sh`
  
- Run this command to create the required IAM roles and Lambda layer:
  
  `./setupEnvironment.sh`
  
- Now, deploy the CloudFormation stack that will build out IAM roles and Lambda function: 
  
  `aws cloudformation deploy --template-file ./setupEnvironment.yaml --stack-name PGPDecryptionStack --capabilities CAPABILITY_NAMED_IAM --parameter-overrides S3BucketName=S3BUCKETNAME`
  - Replace S3BUCKETNAME with whatever you would like to name your S3 bucket. 
  

### Creating Transfer Family Server 
- NOTE: This project requires a Transfer Family server, you must choose one of these three options: 
  Option 1. Use an existing Transfer Family server that is already configured within your environment. 
  Option 2. Deploy a Transfer Family server with a custom Secrets Manager based identity provider via CloudFormation stack. (RECOMMENDED)
  Option 3. Manually create your own Transfer Family server / Transfer Family managed user via the AWS Console. 
  
#### Option 1: Using an existing Transfer Family Server
- No configuration needed at this time, proceed to next step of creating PGP Private Key secret within Secrets Manager.  

#### Option 2: Creating Transfer Family Server with Custom Identity Provider
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
- Select "Store"**

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

