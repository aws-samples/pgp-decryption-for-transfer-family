#!/usr/bin/env bash

# Installing necessary python packages
echo Installing required packages...
cd /home/cloudshell-user
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

# Downloading and building GPG binary from source
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
echo Lambda layer created successfully.
