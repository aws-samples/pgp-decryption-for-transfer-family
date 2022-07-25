#!/usr/bin/env bash
echo Building required IAM policies...
wget https://github.com/aws-samples/pgp-decryption-for-transfer-family/IAM_Policies.zip
unzip IAM_Policies.zip
aws iam create-policy --policy-name PGPDecryptionCloudWatchPolicy --policy-document file://CloudWatchPolicy.json
aws iam create-policy --policy-name PGPDecryptionSecretsManagerPolicy --policy-document file://secretsManagerPolicy.json
aws iam create-policy --policy-name PGPDecryptionManagedWorkflowPolicy --policy-document file://managedWorkflowPolicy.json
aws iam create-policy --policy-name PGPDecryptionS3Policy --policy-document file://s3Policy.json
aws iam create-policy --policy-name PGPDecryptionTransferFamilyPolicy --policy-document file://transferFamilyPolicy.json
echo Installing required packages...
sudo amazon-linux-extras enable python3.8
sudo yum install python3.8 gcc make glibc-static bzip2 pip -y
echo Required packages installed. 
pip3.8 install virtualenv
virtualenv python
cd python
. bin/activate
pip3.8 install python-gnupg
deactivate
rm -rf ./bin
mkdir ./python
mv lib ./python/
wget https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-1.4.23.tar.bz2
tar xjf gnupg-1.4.23.tar.bz2
cd gnupg-1.4.23.tar.bz2
/bin/bash /home/cloudshell-user/python/gnupg-1.4.23/configure
make CLFAGS='-static'
cp g10/gpg /home/cloudshell-user/python/python
cd /home/cloudshell-user/python/python
chmod o+x gpg
cd ..
zip -r lambdaLayer.zip python/
aws lambda publish-layer-version --layer-name python-gnupg --description "Python-GNUPG Module and GPG Binary" --zip-file fileb://lambdaLayer.zip --compatible-runtimes python3.8



