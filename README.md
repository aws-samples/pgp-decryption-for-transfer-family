# PGP Decryption for Transfer Family

## Project Requirements 
### Steps Completed by setupEnvironment.sh script
- Custom Lambda Layer including required binary/python package.

### Steps Completed by CloudFormation Stack
- REQUIRED - Setup Environment Stack: Creates necessary IAM Roles, Lambda Function, and S3 Bucket.

- OPTIONAL - Custom Transfer Family Identity Provider Stack: Creates a Transfer Family server with a custom Lambda identity provider.

### Steps Completed Manually via AWS Console
- Paste PGP Private Key into PGP_PrivateKey secret within Secrets Manager console. 
- Attach Transfer Family Managed Workflow to Transfer Family server within Transfer Family console. 

---

### Overview of Process
1. Open up CloudShell and clone this GitHub repository. 
2. Run setupEnvironment.sh bash script. 
3. Deploy setupEnvironment.yaml CloudFormation stack which creates necessary IAM Roles, Lambda Function, and S3 Bucket.
4. Create a Transfer Family Server / Transfer Family User. (Must pick one of the following options)
    - Option 1: Deploy a Transfer Family server with a custom Secrets Manager based identity provider via CloudFormation stack.
    - Option 2: Use an existing Transfer Family server that is already configured within your environment. 
    - Option 3: Manually create your own Transfer Family server / Transfer Family managed user via the AWS Console. 
5. Add your PGP Private Key in Secrets Manager. 
6. Attach Transfer Family Managed Workflow to Transfer Family server. 

---

## Step-by-Step Instructions

### CloudShell - Deploying setupEnvironment bash script and CloudFormation stacks. 
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
  
  `sam deploy --guided --capabilities CAPABILITY_NAMED_IAM`
  
  
- After the stack creation process completes, run this command and document the ARN, and S3 bucket name: (Required for Custom Transfer Family IDP user creation)
  
  `aws cloudformation describe-stacks | grep -B 6 "Transfer Family User Arn:" > values.txt`
  
  - To access the required ARN / S3 Bucket name needed for Custom Transfer Family IDP user creation, run this command: 
  
    `cat values.txt`
  
![image](https://user-images.githubusercontent.com/59907142/182047911-32e03149-6e3b-4bc5-bf97-6a234bfddc78.png)


--- 

### Creating Transfer Family Server 
- NOTE: This project requires a Transfer Family server, you must choose one of these three options: 
    - Option 1: Deploy a Transfer Family server with a custom Secrets Manager based identity provider via CloudFormation stack.
    - Option 2: Use an existing Transfer Family server that is already configured within your environment. 
    - Option 3: Manually create your own Transfer Family server / Transfer Family managed user via the AWS Console. 
  

#### Option 1: Deploying CloudFormation Stack to Create Transfer Family Server with Custom Identity Provider
- Refer to this link for detailed instructions on deploying a CloudFormation stack that will create a Transfer Family server, custom identity provider, and all the required IAM policies: https://aws.amazon.com/blogs/storage/enable-password-authentication-for-aws-transfer-family-using-aws-secrets-manager-updated/
- Short Summary of Steps Required: 
  - In CloudShell, run the following: 
    
    - Create a new directory for this CloudFormation stack and change into the new directory: 
        
        `mkdir tmp`  
        
        `cd tmp`
    
    - Download the CloudFormation stack using the link mentioned on the blog post linked above, at the time of creating this, the command is as follows: 
    
        `wget https://s3.amazonaws.com/aws-transfer-resources/custom-idp-templates/aws-transfer-custom-idp-secrets-manager-sourceip-protocol-support-apig.zip`

    - After downloading the zip, unzip it: 
  
        `unzip aws-transfer-custom-idp-secrets-manager-sourceip-protocol-support-apig.zip`
    
    - Run the following command:
  
        `sam deploy --guided`
      
    - Enter in a stack name (Example: TransferFamilyServer)
    - Press enter for all other options to leave them as default, refer to image for reference:


        ![image](https://user-images.githubusercontent.com/59907142/181582434-2df2a594-d905-4b69-973b-2fa8880a350d.png)

##### Option 1 Continued: Create Custom Transfer Family Identity Provider User Account
  - In the AWS Secrets Manager console (https://console.aws.amazon.com/secretsmanager), create a new secret by choosing Store a new secret.
  - Choose Other type of secret.
  - Create the following key-value pairs. The key names are case-sensitive.
    - Secret Key: **Password** || Secret Value: **TestPassword1234!**
 
    - Secret Key: **Role** || Secret Value: **arn:aws:iam::INSERT-ACCOUNT-ID:role/PGPDecryptionTransferFamilyUserRole**
      - Refer to the values.txt file created earlier in CloudShell for the exact ARN required. 
     
    - Secret Key: **HomeDirectoryDetails** || Secret Value: **[{"Entry": "/", "Target": "/INSERT-S3-BUCKET-NAME/INSERT-USER-NAME"}]**
      - Refer to the values.txt file created earlier in CloudShell for the exact S3 bucket name required. 
      
     - Secret Key: **HomeDirectoryType** || Secret Value: **LOGICAL**
  - Refer to image for reference: 

![image](https://user-images.githubusercontent.com/59907142/182275511-c049f28f-4de9-4f43-b34a-e30df6224d66.png)
    
  - Click "Next"
  - Name the secret in the format: server-id/username
     - To find the name of the Transfer Family server, go to the Transfer Family console, and select "Servers". 
     - Example: s-177a84c346c05a528/testUser
  - Select "Next" -> "Next" -> "Store"
    

#### Option 2: Use an existing Transfer Family Server + Transfer Family User Account
- No configuration needed at this time, proceed to next step of pasting your PGP Private Key into the PGP_PrivateKey secret within Secrets Manager.  

#### Option 3: Manually Create a Transfer Family Server + Transfer Family User Account via AWS Console
- If you don't want to deploy the custom Transfer Family identity provider via CloudFormation mentioned in the above step, and don't have a currently up and running Transfer Family server, please refer to this link for instructions on how to create a new Transfer Family server + Transfer Family managed user: https://docs.aws.amazon.com/transfer/latest/userguide/getting-started.html

--- 

### Adding Private Key to Secrets Manager
- Navigate to the AWS Secrets Manager console: https://console.aws.amazon.com/secretsmanager 
- Select "Secrets"
- Select the secret named: "PGP_PrivateKey"
- Select "Retrieve secret value"
- Select "Edit"
- Remove the text: "Within the Secrets Manager console, paste your PGP private key here"
- Paste in your PGP Private key
- Select "Save"

---

### Attach Managed Workflow to Transfer Family Server
- On the Transfer Family console, select "Servers"
- Select your desired Transfer Family server
- Under "Additional details", select "Edit"
- Select the Workflow with the description: "Transfer Family Workflow for PGP decryption process"
- Select the Managed workflow execution role with the name: "PGPDecryptionManagedWorkflowRole"
- Select "Save"

---

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

---

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

