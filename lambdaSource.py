import boto3
import botocore
import os
import gnupg
from botocore.exceptions import ClientError
import json
import logging
import pathlib

# Global variables declarations
session = boto3.session.Session()
secretsmanager_client = session.client('secretsmanager')
s3_client = boto3.client('s3')
s3 = boto3.resource('s3')
transfer = boto3.client('transfer')
# privatekeyname needs to be named whatever your GPG private key is named in Secrets Manager. 
privatekeyname = 'PGP_PrivateKey'


# Function to retrieve specified secret_value from secrets manager.     
def get_secret_details(secret_stored_location):
   try:
       response = secretsmanager_client.get_secret_value(SecretId=secret_stored_location)
       return response['SecretString']
   except ClientError as e:
       raise Exception("boto3 client error in get_secret_details: " + e.__str__())
   except Exception as e:
       raise Exception("Unexpected error in get_secret_details: " + e.__str__())

      
# Function that removes the .gpg or .asc file extension from encrypted files after decryption. 
def remove_file_extension(filename):
    base = os.path.basename(filename)
    os.path.splitext(base)
    return os.path.splitext(base)[0]
    
    
# Function that creates a temporary file within the /tmp directory.     
def createtempfile():
    with open('/tmp/tempfile.txt', 'w') as fp:
        pass
    
# Function that downloads file from S3 specified S3 bucket, returns a boolean indicating if file download was a success/failure.  
def downloadfile(bucketname, key, filename):
    try:     
        newfilename = '/tmp/' + filename
        print("New File Name: " + newfilename)
        print("Original File Name: " + filename)
        s3_client.download_file(bucketname, key, newfilename)
        return os.path.exists(newfilename)
    except botocore.exceptions.ClientError as error:
        # Summary of what went wrong
        print(error.response['Error']['Code'])
        # Explanation of what went wrong
        print(error.response['Error']['Message'])
        return False
        
# Function that checks if the uploaded file is encrypted or not and returns corresponding boolean.     
def checkEncryptionStatus(filename):
    file_extension = pathlib.Path(filename).suffix
    if (file_extension == '.asc' or file_extension == '.gpg' or file_extension == '.pgp'): 
        print("This file is encrypted, performing decryption now.")
        return True
    else:
        print("This file is not GPG encrypted, no need to perform decryption.")
        return False
        
# Function that sends workflow step status back to TF Workflow. 
def sendWorkflowStatus(event, status):
    # call the SendWorkflowStepState API to notify the workflow about the step's SUCCESS or FAILURE status
    response = transfer.send_workflow_step_state(
    WorkflowId=event['serviceMetadata']['executionDetails']['workflowId'],
    ExecutionId=event['serviceMetadata']['executionDetails']['executionId'],
    Token=event['token'],
    Status = status
    )
    print(json.dumps(response))
    return {
        'statusCode': 200,
        'body': json.dumps(response)
    }

    
# Lambda handler function
def lambda_handler(event, context):

    # Assigning necessary values from event data to variables. 
    object_path = event['fileLocation']['key']
    file = (object_path.split('/')[-1])
    bucket = event['fileLocation']['bucket']
    username = event['serviceMetadata']['transferDetails']['userName']
   
    # Downloads file from S3.
    print("Object Path: " + object_path)
    print("Bucket: " + bucket)
    downloadStatus = downloadfile(bucket, object_path, file)

    
    # Confirm that the file download was successful. 
    if (downloadStatus):
        print("File was downloaded successfully")
        
        # Store local file name for decryption processing.  
        local_file_name = '/tmp/' + file
    
        # Checks file extension
        encryptedStatus = checkEncryptionStatus(local_file_name)
        
        # If encryptedStatus = true, perform decryption. 
        if (encryptedStatus):
            
            # Create temp file.
            createtempfile()
            
            # Grabs private key from Secrets Manager. 
            PrivateKey = get_secret_details(privatekeyname)
            
            # Set GNUPG home directory and point to where the binary is stored. 
            gpg = gnupg.GPG(gnupghome='/tmp', gpgbinary='/opt/python/gpg', options=['--trust-model', 'always'])
            
            # Import the private key into GNUPG.
            private_import_result = gpg.import_keys(PrivateKey)
            
            # Perform decryption.
            with open(local_file_name, 'rb') as f:
                status = gpg.decrypt_file(f, passphrase = None, output='/tmp/tempfile.txt', always_trust = True)
                
            # Add if statement to account for fake gpgp file
            if (status.ok == True):
                print("Status: OK")
                # Remove .gpg or .asc file extension from file name.
                updatedfilename = remove_file_extension(file)
                # Store the newly decrypted file within the same S3 bucket, but in a different prefix. 
                updatedfilelocation = 'DecryptedFiles/' + username + '/' + updatedfilename
                # Uploading decrypted file into S3. 
                upload_file_name = '/tmp/tempfile.txt'
                s3_client.upload_file(upload_file_name, bucket, updatedfilelocation)
                sendWorkflowStatus(event, 'SUCCESS')
            else:
                print("Status: NOT OK")
                print('OK: ', status.ok)
                print('Decryption Status: ', status.status)
                print('Standard Error: ', status.stderr)
                sendWorkflowStatus(event, 'FAILURE')
            
        # Else, no need to decrypt. 
        else: 
            print("The uploaded file is not encrypted, it has been moved to the DecryptedFiles Prefix.")
            unencryptedfilelocation =  'DecryptedFiles/' + username + '/' + file
            s3 = boto3.client('s3')
            s3.upload_file(local_file_name, bucket, unencryptedfilelocation)
            sendWorkflowStatus(event, 'SUCCESS')
    
    else:
        print("Error downloading the file.")
        sendWorkflowStatus(event, 'FAILURE')
