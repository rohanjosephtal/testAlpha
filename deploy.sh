#!/bin/bash

echo "[default] " >> .s3cfg

echo "access_key = $AWS_ACCESS_KEY_ID" >> .s3cfg

echo "secret_key = $AWS_SECRET_ACCESS_KEY" >> .s3cfg