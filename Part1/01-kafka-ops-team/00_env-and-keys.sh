#!/bin/bash

set -e

# read from parameter
export envid=${1}
export enviddr=${2}
export key=${3}
export secret=${4}
# Read from output
#export envid=$(echo -e "$(terraform output -raw envid)")
#export enviddr=$(echo -e "$(terraform output -raw envid-dr)")
#export key=$(echo -e "$(terraform output -raw key)")
#export secret=$(echo -e "$(terraform output -raw secret)")
echo "
# Prod Cluster environment
export TF_VAR_environment_id="$envid"
# Prod-DR Cluster environment
# export TF_VAR_environment_id="$enviddr"
# Environment Admin 
export TF_VAR_confluent_cloud_api_key="$key"
export TF_VAR_confluent_cloud_api_secret="$secret"" > ../02-env-admin-product-team/env-source

cat ../02-env-admin-product-team/env-source

echo "Now source env variabled"
echo "source ../02-env-admin-product-team/env-source"
echo "and switch to: cd ../02-env-admin-product-team/"