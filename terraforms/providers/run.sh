#!/bin/bash
source ../../credentials/.env
prefix=$random
#login
#-------------------------------------------
# Log into Portal
#-------------------------------------------
_login() {
  bearer=$(curl -s --location --request POST "https://portal.$domain/auth/login" --header 'Content-Type: application/json' \
          --data-raw "{\"username\": \"$TEST_USERNAME\", \"password\": \"$TEST_PASSWORD\"}"| jq  -r ". | .accessToken")

  if [[ "$bearer" == "null" ]]; then
    echo "Getting JWT token: Failed"
    exit 1
  fi

  userId=$(curl -s --location --request GET "https://portal.$domain/user/info" \
  --header "Authorization: Bearer $bearer" \
  --header 'Content-Type: application/json' | jq  -r ". | .id")
  echo "User ID $userId"
}

_create_nodes() {
  echo -n > "$1/nodelist.csv"
  while IFS="," read -r id region zone zoneCode dataSource
  do
    # curl  node/gw
    curl -s --location --request POST "https://portal.$domain/mbr/node" \
      --header "Authorization: Bearer  $bearer" \
      --header 'Content-Type: application/json' \
      --data-raw "{
          \"name\": \"mbr-node-$nodePrefix-$id-$zone\",
          \"blockchain\": \"$blockchain\",
          \"zone\": \"$zoneCode\",
          \"dataSource\": \"$dataSource\",
          \"network\": \"mainnet\"
      }" | jq -r '. | .id, .appKey, .name, .blockchain, .zone' | sed -z -z "s/\n/,/g;s/,$/,$zone,$dataSource\n/" >> "$1/nodelist.csv"
  done < <(tail ../../credentials/eth-sources.csv)
}
_create_gateways() {
  echo -n > "$1/gatewaylist.csv"
  while IFS="," read -r id region zone zoneCode dataSource
    do
      # curl  node/gw
      curl -s --location --request POST "https://portal.$domain/mbr/gateway" \
        --header "Authorization: Bearer  $bearer" \
        --header 'Content-Type: application/json' \
        --data-raw "{
          \"name\":\"mbr-gw-$nodePrefix-$id-$zone\",
          \"blockchain\":\"$blockchain\",
          \"zone\":\"$zoneCode\",
          \"network\":\"mainnet\"}" | jq -r '. | .id, .appKey, .name, .blockchain, .zone' | sed -z -z "s/\n/,/g;s/,$/,$zone\n/" >> "$1/gatewaylist.csv"

    done < <(tail ../../credentials/eth-sources.csv)
}

_prepare_terraform() {
  output="$1/nodes.tf"
  echo 'variable "project_prefix" {
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
  variable "map_machine_types" {
    type = map
  }' > "$output"
  # create  node
  while IFS="," read -r nodeId appId name blockchain zone cloudZone dataSource
  do
    dataSource=$(echo $dataSource | sed "s|\/|\\\/|g")
    echo $ds
    cat node-template |  sed "s/\[\[GATEWAY_ID\]\]/$nodeId/g" | sed  "s/\[\[APP_KEY\]\]/$appId/g" \
      | sed  "s/\[\[ZONE\]\]/$zone/g" | sed  "s/\[\[BLOCKCHAIN\]\]/$blockchain/g" \
      | sed  "s/\[\[DATASOURCE\]\]/$dataSource/g" | sed  "s/\[\[NAME\]\]/$name/g" \
      | sed  "s/\[\[EMAIL\]\]/$email/g" \
      | sed  "s/\[\[CLOUD_ZONE\]\]/$cloudZone/g" | sed  "s/\[\[USER_ID\]\]/$userId/g"  >> $output
  done < <(tail "$1/nodelist.csv")

  #create gw
  while IFS="," read -r nodeId appId name blockchain zone cloudZone
  do
    cat gateway-template |  sed "s/\[\[GATEWAY_ID\]\]/$nodeId/g" | sed  "s/\[\[APP_KEY\]\]/$appId/g" \
      | sed  "s/\[\[ZONE\]\]/$zone/g" | sed  "s/\[\[BLOCKCHAIN\]\]/$blockchain/g" \
      | sed  "s/\[\[NAME\]\]/$name/g" | sed  "s/\[\[CLOUD_ZONE\]\]/$cloudZone/g" \
      | sed  "s/\[\[EMAIL\]\]/$email/g" \
      | sed  "s/\[\[USER_ID\]\]/$userId/g" >> $output
  done < <(tail "$1/gatewaylist.csv")
}
#
# _check_status 'created' node $dirName
# _check_status 'verified' gateway $dirName
#
_check_status() {
  _login
  #Check node status: all is created
  inputFile="$3/${2}list.csv"
  outputFile="$3/${2}status.csv"
  echo "Check status $1 of $2 in Portal"
  echo -n > "$outputFile"
  declare -A statuses
  while IFS="," read -r nodeId appId name blockchain zoneCode cloudZone
    do
      statuses[$nodeId]=''
    done < <(tail "$inputFile")
  total=${#statuses[@]}
  counter=0
  while [[ $counter < $total ]]
    do
      echo -n > "$outputFile"
      counter=0
      for key in "${!statuses[@]}"; do
        echo "Status of $2 $key: ${statuses[$key]}";
        if [ "${statuses[$key]}" != "$1" ]; then
          echo "Checking $2 $nodeId ..."
          res=$(curl -s --location --request GET "https://portal.$domain/mbr/$2/$key" \
            --header "Authorization: Bearer  $bearer" \
            --header 'Content-Type: application/json' \
            | jq -r '. | .id, .appKey, .name, .blockchain, .zone, .status, .geo.ip' \
            | sed -z -z "s/\n/,/g")
          IFS=$',' fields=($res)
          IFS=, ; echo "${fields[*]}" >> "$outputFile"
          statuses[$key]=${fields[5]}
        fi
        if [ "${statuses[$key]}" == "$1" ]; then
          ((counter=counter+1))
        fi
      done
      if [[ $counter < $total ]]; then
        sleep 20
      fi
    done
}

_create_vms() {
  # wait for node to install script
  echo "Create node VMs on GCE: In Progress"
  cd $1
  sudo terraform init -input=false
  if [[ "$?" != "0" ]]; then echo "Faile to execute: terraform init "; exit 1; fi
  sudo terraform plan -out=tfplan -input=false
  if [[ "$?" != "0" ]]; then echo "Faile to execute: terraform plan "; exit 1; fi
  sudo terraform apply -input=false tfplan
  if [[ "$?" != "0" ]]; then echo "Faile to execute: terraform apply "; exit 1; fi
  echo "Create node VMs on GCE: Passed"

  echo "Waiting for nodes to set up"
  cd ".."
  sleep 120
}

#
# Register nodes created in directory $1
#
_register_nodes() {
  while IFS="," read -r nodeId appId name blockchain zone cloudZone
    do
      staking_response=$(curl -s --location --request POST "https://staking.$domain/massbit/admin/register-provider" \
         --header 'Content-Type: application/json' --data-raw "{
           \"operator\": \"$wallet_address\",
           \"providerId\": \"$nodeId\",
           \"providerType\": \"Node\",
           \"blockchain\": \"$blockchain\",
           \"network\": \"mainnet\"
       }" | jq -r ". | .status")
       if [[ "$staking_response" != "success" ]]; then
         echo "Register node $nodeId: Failed"
       else
         echo "Register node $nodeId: Passed"
       fi
    done < <(tail "$1/nodelist.csv")
}
#
# Register gateways created in directory $1
#
_register_gateways() {
  while IFS="," read -r gatewayId appId name blockchain zone cloudZone
    do
      staking_response=$(curl -s --location --request POST "https://staking.$domain/massbit/admin/register-provider" \
         --header 'Content-Type: application/json' --data-raw "{
           \"operator\": \"$wallet_address\",
           \"providerId\": \"$gatewayId\",
           \"providerType\": \"Gateway\",
           \"blockchain\": \"$blockchain\",
           \"network\": \"mainnet\"
       }" | jq -r ". | .status")
       if [[ "$staking_response" != "success" ]]; then
         echo "Register gateway $gatewayId: Failed"
       else
         echo "Register gateway $gatewayId: Passed"
       fi
    done < <(tail "$1/gatewaylist.csv")
}
#
# Stake nodes created in directory $1
#
_stake_nodes() {
  while IFS="," read -r nodeId appId name blockchain zone cloudZone
    do
      curl -s --location --request POST "https://staking.$domain/massbit/staking-provider" \
               --header 'Content-Type: application/json' --data-raw "{
                 \"memonic\": \"$MEMONIC\",
                 \"providerId\": \"$nodeId\",
                 \"amount\": \"$staking_amount\"
             }"
#      staking_response=$(curl -s --location --request POST 'https://staking.massbitroute.dev/massbit/staking-provider' \
#         --header 'Content-Type: application/json' --data-raw "{
#           \"memonic\": \"$MEMONIC\",
#           \"providerId\": \"$nodeId\",
#           \"amount\": \"$staking_amount\"
#       }" | jq -r ". | .status")
#       if [[ "$staking_response" != "success" ]]; then
#         echo "Staking node $nodeId: Failed"
#       else
#         echo "Staking node $nodeId: Passed"
#       fi
    done < <(tail "$1/nodelist.csv")
}
#
# Stake gateways created in directory $1
#
_stake_gateways() {
  while IFS="," read -r gatewayId appId name blockchain zone cloudZone
    do
      staking_response=$(curl -s --location --request POST "https://staking.$domain/massbit/staking-provider" \
         --header 'Content-Type: application/json' --data-raw "{
           \"memonic\": \"$MEMONIC\",
           \"providerId\": \"$gatewayId\",
           \"amount\": \"$staking_amount\"
       }" | jq -r ". | .status")
       if [[ "$staking_response" != "success" ]]; then
         echo "Staking gateway $gatewayId: Failed"
       else
         echo "Staking gateway $gatewayId: Passed"
       fi
    done < <(tail "$1/gatewaylist.csv")
}

_prepare_env() {
  echo "Create test with prefix $1"
  mkdir ./$1
  cp ./terraform.tfvars ./$1/
  cat provider.tf |  sed "s/\[\[CREDENTIALS_PATH\]\]/$credentialsPath/g"  > "./$1/provider.tf"
}
_setup() {
  if [ "x$1" == "x" ]; then
    nodePrefix=$prefix
  else
    nodePrefix=$1
  fi
  _login
  _prepare_env $nodePrefix
  _create_nodes $nodePrefix
  _create_gateways $nodePrefix
  _check_status created node $nodePrefix
  _check_status created gateway $nodePrefix
  _prepare_terraform $nodePrefix
  _create_vms $nodePrefix
  # setup nodes
  _check_status verified node $nodePrefix
  _register_nodes $nodePrefix
  _check_status approved node $nodePrefix
  _stake_nodes $nodePrefix
  _check_status staked node $nodePrefix

  # setup gateways
  _check_status verified gateway $nodePrefix
  _register_gateways $nodePrefix
  _check_status approved gateway $nodePrefix
  _stake_gateways $nodePrefix
  _check_status staked gateway $nodePrefix
}
_clean() {
  if [ "x$1" == "x" ]; then
    echo "Please choose a directory to clean up"
    exit 0
  fi
  _login
  echo "Delete node from portal"
  while IFS="," read -r nodeId appId name blockchain zone cloudZone
     do
       status=$(curl -s --location --request POST "https://staking.$domain/massbit/unregister-provider" \
           --header 'Content-Type: application/json' --data-raw "{
                \"memonic\": \"$MEMONIC\",
                \"providerId\": \"$nodeId\"
            }" | jq -r ". | .status")
         if [[ "$status" != "success" ]]; then
           echo "Unregister node $nodeId: Failed"
         else
           echo "Unregister node $nodeId: Passed"
         fi
       status=$(curl -s --location --request DELETE "https://portal.$domain/mbr/node/$nodeId" \
          --header "Authorization: Bearer $bearer" | jq .status)
        if [[ "$status" != "true" ]]; then
          echo "Delete node $nodeId: Failed"
        else
          echo "Delete node $nodeId: Passed"
        fi
     done < <(tail "$1/nodelist.csv")

  while IFS="," read -r gatewayId appId name blockchain zone cloudZone
     do
       status=$(curl -s --location --request POST "https://staking.$domain/massbit/unregister-provider" \
          --header 'Content-Type: application/json' --data-raw "{
               \"memonic\": \"$MEMONIC\",
               \"providerId\": \"$gatewayId\"
           }" | jq -r ". | .status")
        if [[ "$status" != "success" ]]; then
          echo "Unregister gateway $gatewayId: Failed"
        else
          echo "Unregister gateway $gatewayId: Passed"
        fi
       status=$(curl -s --location --request DELETE "https://portal.$domain/mbr/gateway/$gatewayId" \
          --header "Authorization: Bearer $bearer" | jq .status)
        if [[ "$status" != "true" ]]; then
          echo "Delete gateway $gatewayId: Failed"
        else
          echo "Delete gateway $gatewayId: Passed"
        fi

     done < <(tail "$1/gatewaylist.csv")
  echo "Cleaning up VMs: In Progress"
  cd $1
  sudo terraform destroy
  if [[ "$?" != "0" ]]; then echo "Faile to execute: terraform destroy "; exit 1; fi
  echo "Cleaning up VMs: Passed"
  cd ..
  sudo rm -rf $1
}

$@
