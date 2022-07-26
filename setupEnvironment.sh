#!/usr/bin/env bash
echo Building required IAM policies...

# Download IAM Policies from GitHub repo
wget https://github.com/aws-samples/pgp-decryption-for-transfer-family/IAM_Policies.zip
unzip IAM_Policies.zip

# IAM Role Creation
aws iam create-role --role-name PGPDecryptionLambdaExecutionRole1 --assume-role-policy-document file://lambda-trust-policy.json
aws iam create-role --role-name PGPDecryptionManagedWorklowRole1 --assume-role-policy-document file://transfer-trust-policy.json

# Attaching policies ot Lambda Execution Role
aws iam put-role-policy --role-name PGPDecryptionLambdaExecutionRole1 --policy-name PGPDecryptionCloudWatchPolicy --policy-document file://CloudWatchPolicy.json
aws iam put-role-policy --role-name PGPDecryptionLambdaExecutionRole1 --policy-name PGPDecryptionSecretsManagerPolicy --policy-document file://secretsManagerPolicy.json
aws iam put-role-policy --role-name PGPDecryptionLambdaExecutionRole1 --policy-name PGPDecryptionS3Policy --policy-document file://s3Policy.json
aws iam put-role-policy --role-name PGPDecryptionLambdaExecutionRole1 --policy-name PGPDecryptionTransferFamilyPolicy --policy-document file://transferFamilyPolicy.json

# Attaching policies to Managed Workflow Execution Role
aws iam put-role-policy --role-name PGPDecryptionManagedWorklowRole1 --policy-name PGPDecryptionManagedWorkflowPolicy --policy-document file://managedWorkflowPolicy.json
aws iam put-role-policy --role-name PGPDecryptionManagedWorklowRole1 --policy-name PGPDecryptionTransferFamilyPolicy --policy-document file://transferFamilyPolicy.json

# Installing required packages
echo Installing required packages...
sudo amazon-linux-extras enable python3.8
sudo yum install python3.8 gcc make glibc-static bzip2 pip -y
echo Required packages installed. 
pip3.8 install virtualenv

# Create and activate virtualenvironment to install required Python packages
virtualenv python
cd python
. bin/activate
pip3.8 install python-gnupg
deactivate
rm -rf ./bin
mkdir ./python
mv lib ./python/

# Downloading GPG binary and compiling it from source
wget https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-1.4.23.tar.bz2
tar xjf gnupg-1.4.23.tar.bz2
cd gnupg-1.4.23.tar.bz2
/bin/bash /home/cloudshell-user/python/gnupg-1.4.23/configure
make CLFAGS='-static'
cp g10/gpg /home/cloudshell-user/python/python
cd /home/cloudshell-user/python/python
chmod o+x gpg
cd ..

# Zip everything up and push to Lambda as a layer
zip -r lambdaLayer.zip python/
aws lambda publish-layer-version --layer-name python-gnupg --description "Python-GNUPG Module and GPG Binary" --zip-file fileb://lambdaLayer.zip --compatible-runtimes python3.8
