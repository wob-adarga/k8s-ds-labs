#!/bin/bash

export AWS_PROFILE=adarga-datascience-admin
export AWS_DEFAULT_REGION=eu-west-2
export AWS_SDK_LOAD_CONFIG=1

kfctl delete -V -f ./kfctl_aws_cognito.v1.2.0.yaml --delete_storage --force-deletion
