#!/bin/bash

exec sudo touch /tmp/.s3cfg

echo "[default] " >> /tmp/.s3cfg

echo "access_key = $AWS_ACCESS_KEY_ID" >> /tmp/.s3cfg

echo "secret_key = $AWS_SECRET_ACCESS_KEY" >> /tmp/.s3cfg