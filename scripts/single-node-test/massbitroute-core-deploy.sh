#!/bin/bash
############# SENSITIVE DATA
# PRIVATE_GIT_GATEWAY_WRITE_USER=""
# GIT_GATEWAY_WRITE_PASSWORD=""
PRIVATE_GIT_DOMAIN="git.massbitroute.dev"
PRIVATE_GIT_READ_PASSWORD=$(echo envenv | sha1sum | cut -d " " -f 1)
PRIVATE_GIT_READ_USERNAME="env"

if [ -z "$1" ]
  then
    echo "ERROR: Git branch name is required"
    exit 1
fi
GIT_BRANCH=$1

if [ -z "$2" ]
  then
    echo "ERROR: Git MERGE branch name is required"
    exit 1
fi
GIT_MERGE_BRANCH=$2


#-------------------------------------------
# create terraform file for new node
#-------------------------------------------
sudo echo 'variable "project_prefix" {
  type        = string
  description = "The project prefix (mbr)."
}
variable "environment" {
  type        = string
  description = "Environment: dev, test..."
}
variable "default_zone" {
  type = string
}
variable "network_interface" {
  type = string
}
variable "email" {
  type = string
}
variable "map_machine_types" {
  type = map
}' >test-nodes.tf


nodeId="$(echo $RANDOM | md5sum | head -c 5)"
cat massbitroute-core-template-single | \
     sed "s/\[\[API_NODE_ID\]\]/$nodeId/g" | \
    sed "s/\[\[BRANCH_NAME\]\]/$GIT_BRANCH/g" | \
    sed "s/\[\[MERGE_BRANCH\]\]/$GIT_MERGE_BRANCH/g" | \
    sed "s/\[\[PRIVATE_GIT_READ_USERNAME\]\]/$PRIVATE_GIT_READ_USERNAME/g" | \
    sed "s/\[\[PRIVATE_GIT_READ_PASSWORD\]\]/$PRIVATE_GIT_READ_PASSWORD/g" | \
    sed "s/\[\[PRIVATE_GIT_DOMAIN\]\]/$PRIVATE_GIT_DOMAIN/g"  >> test-nodes.tf


#-------------------------------------------
#  Spin up new VM on GCE
#-------------------------------------------
echo "Create new node VMs on GCE: In Progress"
terraform init -input=false
if [[ "$?" != "0" ]]; then
  echo "terraform init: Failed "
  exit 1
fi
sudo terraform plan -out=tfplan -input=false
if [[ "$?" != "0" ]]; then
  echo "terraform plan: Failed "
  exit 1
fi
sudo terraform apply -input=false tfplan
if [[ "$?" != "0" ]]; then
  echo "terraform apply: Failed"
  exit 1
fi
echo "Create node VMs on GCE: Passed"

NEW_API_IP=$(terraform output -raw mbrcore_public_ip)
echo $NEW_API_IP > MASSBITROUTE_CORE_IP



# #-------------------------------------------
# #  Update new IP in GWMan
# #-------------------------------------------
# # save old IP 
# NEW_API_IP=$(terraform output -raw mbrcore_public_ip)

# sudo mkdir -p /massbit/gwman
# sudo chmod 766 /massbit/gwman
# cd /massbit/gwman
# git clone http://$PRIVATE_GIT_GATEWAY_WRITE_USER:$GIT_GATEWAY_WRITE_PASSWORD@$PRIVATE_GIT_DOMAIN/massbitroute/gwman.git 

# OLD_API_IP=$(egrep -i "^dapi A" data/zones/massbitroute.dev | cut -d " " -f 3)

# cd data/zones
# cp massbitroute.dev massbitroute.dev.bak

# # replace new IP 
# sed -i "s/^dapi A.*/dapi A $NEW_API_IP/g"

# git add .
# git commit -m "Update entry for dapi [OLD] $OLD_API_IP - [NEW] $NEW_API_IP"
# # git push origin master


# # waiting for DNS to udpate
# while [ "$(nslookup dapi.massbitroute.dev  | grep "Address: $NEW_API_IP")" != "Address: $NEW_API_IP" ]
# do
#   echo "Waiting for DNS to update new API IP ..."
#   sleep 10
# done 
# echo "DNS entry for api updated: ${nslookup dapi.massbitroute.dev  | grep "Address: $NEW_API_IP"}"
