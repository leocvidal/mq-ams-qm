FROM cp.icr.io/cp/ibm-mqadvanced-server-integration:9.3.0.0-r2
# Copy in the keystore.conf
copy conf/keystore.conf /run
