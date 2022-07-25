## PGP Decryption for Transfer Family

### Configuring your AWS Environment
#### Creating IAM Policies and Lambda Layer
- Open up CloudShell within your AWS account. 
- Run this command to download the setupEnvironment.sh script and the required IAM policies: 
  
  `wget https://github.com/aws-samples/pgp-decryption-for-transfer-family/blob/main/setupEnvironment.sh https://github.com/aws-samples/pgp-decryption-for-transfer-family/blob/main/IAM_Policies.zip`
  
- Run this command to create the required IAM policies and Lambda layer:
  
  `./setupEnvironment.sh`
  
  
- After running script, navigate to IAM -> Roles on the AWS Management Console. 

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


#### Deploying Custom Transfer Family Identity Provider (OPTIONAL)
- NOTE: If you already have a Transfer Family server in place that you want to use, or if you don't want to use a custom IDP, you can ignore this step. However, this project does require that you have a Transfer Family server running within your AWS account, so if you don't currently have one, I'd recommend deploying this CloudFormation stack as it will create the Transfer Family server + all the required IAM policies for you.  
- Refer to this link for detailed instructions on deploying the Custom Transfer Family Identity Provider: [https://aws.amazon.com/blogs/storage/enable-password-authentication-for-aws-transfer-family-using-aws-secrets-manager-updated/](url)

















## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

