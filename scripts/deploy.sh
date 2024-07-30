#!/bin/bash
export KEYDB=server.kdb
export KEYP12=server.p12
export KEY_APP=application.key
export CERT_APP=application.crt
export KEYDB_APP=application.kdb
export KEYP12_APP=application.p12
export PASSWORD=password

# Create a private key and certificate in PEM format, for the server to use
echo "#### Create a private key and certificate in PEM format, for the server to use"
openssl req \
       -newkey rsa:2048 -nodes -keyout ${KEY} \
       -subj "/CN=mq queuemanager/OU=ibm mq" \
       -x509 -days 3650 -out ${CERT}

ls -ali ${CERT}

openssl pkcs12 -export -out ${KEYP12} -inkey ${KEY} -in ${CERT} -passout pass:password
ls -ali ${KEYP12}

# Create a private key and certificate in PEM format, for the application to use
echo "#### Create a private key and certificate in PEM format, for the application to use"
openssl req \
       -newkey rsa:2048 -nodes -keyout ${KEY_APP} \
       -subj "/CN=application1/OU=app team1" \
       -x509 -days 3650 -out ${CERT_APP}

openssl pkcs12 -export -out ${KEYP12_APP} -inkey ${KEY_APP} -in ${CERT_APP} -passout pass:password
ls -ali ${KEYP12_APP}

echo "Delete files on mq containers..."
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "rm /tmp/jenkins_pipeline/*"
oc cp ./${CERT} mq-temp-ibm-mq-0:/tmp/jenkins_pipeline -n jenkins -c qmgr
oc cp ./${CERT_APP} mq-temp-ibm-mq-0:/tmp/jenkins_pipeline -n jenkins -c qmgr
oc cp ./${KEYP12} mq-temp-ibm-mq-0:/tmp/jenkins_pipeline -n jenkins -c qmgr
oc cp ./${KEYP12_APP} mq-temp-ibm-mq-0:/tmp/jenkins_pipeline -n jenkins -c qmgr

# Add the key and certificate to a kdb key store, for the server to use
echo "#### Creating kdb key store, for the server to use"
#runmqckm -keydb -create -db ${KEYDB} -pw ${PASSWORD} -type cms -stash
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqckm -keydb -create -db /tmp/jenkins_pipeline/${KEYDB} -pw ${PASSWORD} -type cms -stash"

echo "#### Adding certs and keys to kdb key store, for the server to use"
#runmqckm -cert -add -db ${KEYDB} -file ${CERT} -stashed
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqckm -cert -add -db /tmp/jenkins_pipeline/${KEYDB} -file /tmp/jenkins_pipeline/${CERT} -stashed"
#runmqckm -cert -import -file ${KEYP12} -pw password -target ${KEYDB} -target_stashed
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqckm -cert -import -file /tmp/jenkins_pipeline/${KEYP12} -pw password -target /tmp/jenkins_pipeline/${KEYDB} -target_stashed"

# Add the key and certificate to a kdb key store, for the application to use
echo "#### Add the key and certificate to a kdb key store, for the application to use"
#runmqckm -keydb -create -db ${KEYDB_APP} -pw ${PASSWORD} -type cms -stash
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqckm -keydb -create -db /tmp/jenkins_pipeline/${KEYDB_APP} -pw ${PASSWORD} -type cms -stash"

echo "#### Adding certs and keys to kdb key store, for the application to use"
#runmqckm -cert -add -db ${KEYDB_APP} -file ${CERT_APP} -stashed
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqckm -cert -add -db /tmp/jenkins_pipeline/${KEYDB_APP} -file /tmp/jenkins_pipeline/${CERT_APP} -stashed"
#runmqckm -cert -import -file ${KEYP12_APP} -pw password -target ${KEYDB_APP} -target_stashed -label 1 -new_label aceclient
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqckm -cert -import -file /tmp/jenkins_pipeline/${KEYP12_APP} -pw password -target /tmp/jenkins_pipeline/${KEYDB_APP} -target_stashed -label 1 -new_label aceclient"

# Add the certificate to a trust store in JKS format, for Server to use when connecting
echo "#### Creating JKS format, for Server to use when connecting"
#runmqckm -keydb -create -db server.jks -type jks -pw password
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqckm -keydb -create -db /tmp/jenkins_pipeline/server.jks -type jks -pw password"

echo "#### Adding certs and keys to JKS"
#runmqckm -cert -add -db server.jks -file ${CERT_APP} -pw password
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqckm -cert -add -db /tmp/jenkins_pipeline/server.jks -file /tmp/jenkins_pipeline/${CERT_APP} -pw password"
#runmqckm -cert -import -file ${KEYP12} -pw password -target server.jks -target_pw password
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqckm -cert -import -file /tmp/jenkins_pipeline/${KEYP12} -pw password -target /tmp/jenkins_pipeline/server.jks -target_pw password"

# Add the certificate to a trust store in JKS format, for Client to use when connecting
echo "#### Creating JKS format, for application to use when connecting"
#runmqckm -keydb -create -db application.jks -type jks -pw password
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqckm -keydb -create -db /tmp/jenkins_pipeline/application.jks -type jks -pw password"

echo "#### Adding certs and keys to JKS"
#runmqckm -cert -add -db application.jks -file ${CERT} -pw password
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqckm -cert -add -db /tmp/jenkins_pipeline/application.jks -file /tmp/jenkins_pipeline/${CERT} -pw password"
#runmqckm -cert -import -file ${KEYP12_APP} -pw password -target application.jks -target_pw password
oc exec mq-temp-ibm-mq-0 -n jenkins -- bash -c "runmqckm -cert -import -file /tmp/jenkins_pipeline/${KEYP12_APP} -pw password -target /tmp/jenkins_pipeline/application.jks -target_pw password"





oc project westpac-demo
set +e
# Remove the runnning queue manager instance (if any)

# oc delete QueueManager mq-ams

# Delete the route object and secret for the QueueManager keystore (if any), and the mqsc configMap
oc delete route mq-amsroute
oc delete secret mqamskey
oc delete configMap ams1-mqsc
oc delete secret kdb-secret
oc delete secret ams-conf
set -e
# Create the route and the keystore secret and mqsc configMap
oc apply -f mq-amsRoute.yaml
oc create secret tls mqamskey --cert=./tls/tls.crt --key=./tls/tls.key
oc create secret generic kdb-secret --from-file=ams.kdb=./conf/ams.kdb --from-file=ams.sth=./conf/ams.sth 
oc create secret generic ams-conf --from-file=keystore.conf=./conf/keystore.conf

oc create -f mqsc/mqsc.yaml

set -e
# oc apply -f mqeploy.yaml
oc apply -f mqNoinitC.yaml
