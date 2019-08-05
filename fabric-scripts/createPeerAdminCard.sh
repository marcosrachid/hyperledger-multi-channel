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

Usage() {
	echo ""
	echo "Usage: ./createPeerAdminCard.sh [-h host] [-n]"
	echo ""
	echo "Options:"
	echo -e "\t-h or --host:\t\t(Optional) name of the host to specify in the connection profile"
	echo -e "\t-n or --noimport:\t(Optional) don't import into card store"
	echo ""
	echo "Example: ./createPeerAdminCard.sh"
	echo ""
	exit 1
}

Parse_Arguments() {
	while [ $# -gt 0 ]; do
		case $1 in
			--help)
				HELPINFO=true
				;;
			--host | -h)
                shift
				HOST="$1"
				;;
            --noimport | -n)
				NOIMPORT=true
				;;
		esac
		shift
	done
}

HOST=localhost
Parse_Arguments $@

if [ "${HELPINFO}" == "true" ]; then
    Usage
fi

# Grab the current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "${HL_COMPOSER_CLI}" ]; then
  HL_COMPOSER_CLI=$(which composer)
fi

echo
# check that the composer command exists at a version >v0.16
COMPOSER_VERSION=$("${HL_COMPOSER_CLI}" --version 2>/dev/null)
COMPOSER_RC=$?

if [ $COMPOSER_RC -eq 0 ]; then
    AWKRET=$(echo $COMPOSER_VERSION | awk -F. '{if ($2<20) print "1"; else print "0";}')
    if [ $AWKRET -eq 1 ]; then
        echo Cannot use $COMPOSER_VERSION version of composer with fabric 1.2, v0.20 or higher is required
        exit 1
    else
        echo Using composer-cli at $COMPOSER_VERSION
    fi
else
    echo 'No version of composer-cli has been detected, you need to install composer-cli at v0.20 or higher'
    exit 1
fi

# Org1
cat << EOF > DevServer_connection.json
{
    "name": "hlfv1",
    "x-type": "hlfv1",
    "x-commitTimeout": 300,
    "version": "1.0.0",
    "client": {
        "organization": "Org1",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "300",
                    "eventHub": "300",
                    "eventReg": "300"
                },
                "orderer": "300"
            }
        }
    },
    "channels": {
        "composerchannel": {
            "orderers": [
                "orderer.example.com"
            ],
            "peers": {
                "peer0.org1.example.com": {}
            }
        }
    },
    "organizations": {
        "Org1": {
            "mspid": "Org1MSP",
            "peers": [
                "peer0.org1.example.com"
            ],
            "certificateAuthorities": [
                "ca.org1.example.com"
            ]
        }
    },
    "orderers": {
        "orderer.example.com": {
            "url": "grpc://${HOST}:7050"
        }
    },
    "peers": {
        "peer0.org1.example.com": {
            "url": "grpc://${HOST}:7051"
        }
    },
    "certificateAuthorities": {
        "ca.org1.example.com": {
            "url": "http://${HOST}:7054",
            "caName": "ca.org1.example.com"
        }
    }
}
EOF

PRIVATE_KEY="${DIR}"/composer/$(ls -1 crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/*_sk)
CERT="${DIR}"/composer/$(ls crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/*.pem)

if [ "${NOIMPORT}" != "true" ]; then
    CARDOUTPUT=/tmp/Org1Admin@hlfv1.card
else
    CARDOUTPUT=Org1Admin@hlfv1.card
fi

"${HL_COMPOSER_CLI}"  card create -p DevServer_connection.json -u Org1Admin -c "${CERT}" -k "${PRIVATE_KEY}" -r Org1Admin -r ChannelAdmin --file $CARDOUTPUT

if [ "${NOIMPORT}" != "true" ]; then
    if "${HL_COMPOSER_CLI}"  card list -c Org1Admin@hlfv1 > /dev/null; then
        "${HL_COMPOSER_CLI}"  card delete -c Org1Admin@hlfv1
    fi

    "${HL_COMPOSER_CLI}"  card import --file /tmp/Org1Admin@hlfv1.card 
    "${HL_COMPOSER_CLI}"  card list
    echo "Hyperledger Composer Org1Admin card has been imported, host of fabric specified as '${HOST}'"
    rm /tmp/Org1Admin@hlfv1.card
else
    echo "Hyperledger Composer Org1Admin card has been created, host of fabric specified as '${HOST}'"
fi

# Org2
cat << EOF > DevServer_connection.json
{
    "name": "hlfv1",
    "x-type": "hlfv1",
    "x-commitTimeout": 300,
    "version": "1.0.0",
    "client": {
        "organization": "Org1",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "300",
                    "eventHub": "300",
                    "eventReg": "300"
                },
                "orderer": "300"
            }
        }
    },
    "channels": {
        "composerchannel": {
            "orderers": [
                "orderer.example.com"
            ],
            "peers": {
                "peer0.org1.example.com": {}
            }
        }
    },
    "organizations": {
        "Org1": {
            "mspid": "Org1MSP",
            "peers": [
                "peer0.org1.example.com"
            ],
            "certificateAuthorities": [
                "ca.org1.example.com"
            ]
        }
    },
    "orderers": {
        "orderer.example.com": {
            "url": "grpc://${HOST}:7050"
        }
    },
    "peers": {
        "peer0.org1.example.com": {
            "url": "grpc://${HOST}:7051"
        }
    },
    "certificateAuthorities": {
        "ca.org1.example.com": {
            "url": "http://${HOST}:7054",
            "caName": "ca.org1.example.com"
        }
    }
}
EOF

PRIVATE_KEY="${DIR}"/composer/$(ls crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/keystore/*_sk)
CERT="${DIR}"/composer/$(ls crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/signcerts/*.pem)

if [ "${NOIMPORT}" != "true" ]; then
    CARDOUTPUT=/tmp/Org2Admin@hlfv1.card
else
    CARDOUTPUT=Org2Admin@hlfv1.card
fi

"${HL_COMPOSER_CLI}"  card create -p DevServer_connection.json -u Org2Admin -c "${CERT}" -k "${PRIVATE_KEY}" -r Org2Admin -r ChannelAdmin --file $CARDOUTPUT

if [ "${NOIMPORT}" != "true" ]; then
    if "${HL_COMPOSER_CLI}"  card list -c Org2Admin@hlfv1 > /dev/null; then
        "${HL_COMPOSER_CLI}"  card delete -c Org2Admin@hlfv1
    fi

    "${HL_COMPOSER_CLI}"  card import --file /tmp/Org2Admin@hlfv1.card 
    "${HL_COMPOSER_CLI}"  card list
    echo "Hyperledger Composer Org2Admin card has been imported, host of fabric specified as '${HOST}'"
    rm /tmp/Org2Admin@hlfv1.card
else
    echo "Hyperledger Composer Org2Admin card has been created, host of fabric specified as '${HOST}'"
fi

# Org3
cat << EOF > DevServer_connection.json
{
    "name": "hlfv1",
    "x-type": "hlfv1",
    "x-commitTimeout": 300,
    "version": "1.0.0",
    "client": {
        "organization": "Org1",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "300",
                    "eventHub": "300",
                    "eventReg": "300"
                },
                "orderer": "300"
            }
        }
    },
    "channels": {
        "composerchannel": {
            "orderers": [
                "orderer.example.com"
            ],
            "peers": {
                "peer0.org1.example.com": {}
            }
        }
    },
    "organizations": {
        "Org1": {
            "mspid": "Org1MSP",
            "peers": [
                "peer0.org1.example.com"
            ],
            "certificateAuthorities": [
                "ca.org1.example.com"
            ]
        }
    },
    "orderers": {
        "orderer.example.com": {
            "url": "grpc://${HOST}:7050"
        }
    },
    "peers": {
        "peer0.org1.example.com": {
            "url": "grpc://${HOST}:7051"
        }
    },
    "certificateAuthorities": {
        "ca.org1.example.com": {
            "url": "http://${HOST}:7054",
            "caName": "ca.org1.example.com"
        }
    }
}
EOF

PRIVATE_KEY="${DIR}"/composer/$(ls crypto-config/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp/keystore/*_sk)
CERT="${DIR}"/composer/$(ls crypto-config/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp/signcerts/*.pem)

if [ "${NOIMPORT}" != "true" ]; then
    CARDOUTPUT=/tmp/Org3Admin@hlfv1.card
else
    CARDOUTPUT=Org3Admin@hlfv1.card
fi

"${HL_COMPOSER_CLI}"  card create -p DevServer_connection.json -u Org3Admin -c "${CERT}" -k "${PRIVATE_KEY}" -r Org3Admin -r ChannelAdmin --file $CARDOUTPUT

if [ "${NOIMPORT}" != "true" ]; then
    if "${HL_COMPOSER_CLI}"  card list -c Org3Admin@hlfv1 > /dev/null; then
        "${HL_COMPOSER_CLI}"  card delete -c Org3Admin@hlfv1
    fi

    "${HL_COMPOSER_CLI}"  card import --file /tmp/Org3Admin@hlfv1.card 
    "${HL_COMPOSER_CLI}"  card list
    echo "Hyperledger Composer Org3Admin card has been imported, host of fabric specified as '${HOST}'"
    rm /tmp/Org3Admin@hlfv1.card
else
    echo "Hyperledger Composer Org3Admin card has been created, host of fabric specified as '${HOST}'"
fi
