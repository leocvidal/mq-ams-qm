# mq-ams-qm

This repository is to be used for creating an MQ Queue Manager on OCP, version 4.10.x, with IBM's Cloudpak for Integration Installed (verison 2022.2.1 or higher).

The artifacts include an MQ QueueManager Object Custom resource definition and a route object associated with the channel created for access to the queue manager from outside the cluster, as well as an MQSC source yaml used to create a config-map object used for configuring the queue manager. 

In addition, a tls key and cert is provided for the queue manager's keystore, and a secret is created 
using these artifacts. These files can also be used to create a keystore for the MQ client to connect, for simplicity.
Alternatively you can fork this repository and use your own certs and keys.

In addition an AMS policy in enabled on the queue IVT.P. This may be used to demonstrate Channel Interception for application of policy on messages.

An intermediate image must first be built using the script build.sh in order to copy the keytore.conf file into the IBM supplied base image. 
This script expects an ImageStream object called demomq to exisit in the mq namespace.

Once this is built the deploy.sh uses the built image whcih is pushed to the local registry to deploy the queue manager.
Note the imagePullSecret in the mqDeploy.yaml file will need to match that in the mq namespace on your cluster. 

In the client directory there is a sample CCDT and a keystore for connecting to the queue manger from outside the cluster. 
