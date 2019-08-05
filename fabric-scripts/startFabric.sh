#!/bin/bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Exit on first error, print all commands.
set -e

FABRIC_START_TIMEOUT=15

# Grab the current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_FILE="${DIR}"/composer/docker-compose.yml

docker-compose -f "${DOCKER_FILE}" down
docker-compose -f "${DOCKER_FILE}" up -d

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
echo "sleeping for ${FABRIC_START_TIMEOUT} seconds to wait for fabric to complete start up"
sleep ${FABRIC_START_TIMEOUT}

# Org1
# Create the channel
docker exec peer.org1.example.com peer channel create -o orderer.example.com:7050 -c ChannelOrg12 -f /etc/hyperledger/configtx/channel12.tx

# Join peer.org1.example.com to the channel.
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer.org1.example.com peer channel join -b channel12.block

# Org2
# Create the channel
docker exec peer.org2.example.com peer channel create -o orderer.example.com:7050 -c ChannelOrg23 -f /etc/hyperledger/configtx/channel23.tx

# Join peer.org2.example.com to the channel.
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer.org2.example.com peer channel join -b channel23.block

# Org3
# Create the channel
docker exec peer.org3.example.com peer channel create -o orderer.example.com:7050 -c ChannelOrg13 -f /etc/hyperledger/configtx/channel13.tx

# Join peer.org3.example.com to the channel.
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org3.example.com/msp" peer.org3.example.com peer channel join -b channel13.block
