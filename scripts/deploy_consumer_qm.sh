#!/bin/bash
export KEY=ams.key
export CERT=ams.crt
export KEYDB=ams.kdb
export KEYP12=ams.p12
export PASSWORD=password
export STASH=ams.sth

rm ${KEY}
rm ${CERT}
rm ${KEYP12}
rm ${STASH}

# Create a private key and certificate in PEM format, for the server to use
echo "#### Create a private key and certificate in PEM format, for the server to use"
openssl req \
       -newkey rsa:1024 -nodes -keyout ${KEY} \
       -subj "/CN=ams/O=mqams/C=AU" \
       -x509 -days 3650 -out ${CERT}

ls -ali ${CERT}

openssl pkcs12 -export -out ${KEYP12} -inkey ${KEY} -in ${CERT} -passout pass:password
ls -ali ${KEYP12}

# Remove files from mq temp container under /tmp/jenkins_pipeline/
echo "Delete files on mq container..."
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "rm /tmp/jenkins_pipeline/*"

# Copy files to mq temp container under /tmp/jenkins_pipeline folder
echo "Copying created cert files to the mq container..."
oc cp ./${CERT} mq-temp-ibm-mq-0:/tmp/jenkins_pipeline -n jenkins -c qmgr
oc cp ./${KEYP12} mq-temp-ibm-mq-0:/tmp/jenkins_pipeline -n jenkins -c qmgr

# Create the kdb key store
echo "#### Creating kdb key store, for the server to use"
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqakm -keydb -create -db /tmp/jenkins_pipeline/${KEYDB} -pw ${PASSWORD} -stash"

# Add the key and certificate to a kdb key store, for the server to use
echo "#### Adding certs and keys to kdb key store, for the server to use"
#runmqckm -cert -add -db ${KEYDB} -file ${CERT} -stashed
#oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqckm -cert -add -db /tmp/jenkins_pipeline/${KEYDB} -file /tmp/jenkins_pipeline/${CERT} -stashed"
#runmqckm -cert -import -file ${KEYP12} -pw password -target ${KEYDB} -target_stashed
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqakm -cert -import -file /tmp/jenkins_pipeline/${KEYP12} -pw password -target /tmp/jenkins_pipeline/${KEYDB} -target_stashed -new_label label1"

#Copy .kdb to /conf directory for Jenkins pipeline execution
oc cp mq-temp-ibm-mq-0:/tmp/jenkins_pipeline/${KEYDB} ./conf/${KEYDB} -n jenkins -c qmgr
oc cp mq-temp-ibm-mq-0:/tmp/jenkins_pipeline/${STASH} ./conf/${STASH} -n jenkins -c qmgr

#Inititate execution
oc project consumer-app
set +e
# Remove the runnning queue manager instance (if any)

# oc delete QueueManager mq-ams
oc delete qmgr mq-ams-consumer-app

# Delete the route object and secret for the QueueManager keystore (if any), and the mqsc configMap
oc delete route mq-ams-consumer-app-ibm-mq-qm
oc delete secret mqamskey
oc delete configMap ams1-mqsc-remote
oc delete secret kdb-secret
oc delete secret ams-conf
set -e
# Create the route and the keystore secret and mqsc configMap
oc apply -f mq-amsRoute.yaml
oc create secret tls mqamskey --cert=./tls/tls.crt --key=./tls/tls.key
oc create secret generic kdb-secret --from-file=ams.kdb=./conf/ams.kdb --from-file=ams.sth=./conf/ams.sth 
oc create secret generic ams-conf --from-file=keystore.conf=./conf/keystore.conf

oc create -f mqsc/mqsc_remote.yaml
 
oc apply -f mqNoinitC_remote.yaml