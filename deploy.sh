#!/bin/bash

exec sudo touch /tmp/credentials
echo "[default]" >> /tmp/credentials

echo "aws_access_key_id"=$AWS_ACCESS_KEY_ID
echo "aws_secret_access_key"=$AWS_SECRET_ACCESS_KEY

echo cat /tmp/credentials