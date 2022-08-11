***********************************************************************************************************************************************************************
##### NOTE: This exact Transfer Family Managed Workflow is created by deploying the template.yaml CloudFormation stack. These instructions are simply here for reference of how you could create this Managed Workflow manually via the AWS console. 
***********************************************************************************************************************************************************************

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
