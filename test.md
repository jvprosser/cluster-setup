# security-setup

## 1. TLS

  ### 1. 	Preparation
  * Confirm the installation of or Download and install the Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files from the Oracle website into /usr/java/latest/jre/lib/security

Private and public key pairs and CSRs for all hosts can be generated using the Cloudera Professional Services Certificate ToolKit.   Download and install this toolkit.  For this example, the toolkit directory will be named CertToolkit-master.

Once you locate that directory on the Cloudera Manager host, change directory to CertToolkit-master/bin

Within that directory is a file called defaults.yaml.

This file should be reviewed and modified as needed for your environment, but you should make sure that he JAVA and CM information is correct, and also make sure TLS_LEVEL=3

 ### 2. 	Subject Alternative Name
  * Find out if there is a load balancer in front of the cluster and whether its doing pass-through.  The certificates need to know about the VIP front-end’s hostname's Subject Alternate Name section.
  
Subject Alternative Name extensions should be set on any of the CSRs that will be behind the VIP.

They are specified using the following configuration entry in the defaults.yaml file:

`CERT_ALT_NAMES_FILE: alt_names.txt`

The alt_names.txt file contains mappings from each back-end hostname to the hostnames that will be assigned to the load-balancer VIPs in front of them.  These include the actual VIP names (e.g. hueVIP-prod.example-internal.net) as well any global aliases (e.g. hbaseVIP.example-internal.net) and short hostname-only variants (e.g. hbaseVIP) along with the FQDN of the host itself.  Below is an example

Example alt_names.txt:

```master1 DNS:globalCMVIP.example-internal.net,DNS:oozie-prod.example-internal.net,DNS:globalCMVIP,DNS:oozie,DNS:oozie.example-internal.net
master2 DNS:globalCMVIP.example-internal.net,DNS:oozie-prod.example-internal.net,DNS:globalCMVIP,DNS:oozie,DNS:oozie.example-internal.net
edgeNode1 DNS:hueVIP-prod.example-internal.net,DNS:hbaseVIP-prod.example-internal.net,DNS:hiveVIP-prod.example-internal.net, DNS:sshVIP-prod.example-internal.net,DNS:hueVIP,DNS:hbaseVIP,DNS:hiveVIP,DNS:sshVIP, DNS:hueVIP.example-internal.net, DNS:hbaseVIP.example-internal.net,DNS:hiveVIP.example-internal.net,DNS:sshVIP.example-internal.net
edgeNode2 DNS:hueVIP-prod.example-internal.net,DNS:hbaseVIP-prod.example-internal.net, ,DNS:hiveVIP-prod.example-internal.net,DNS:sshVIP-prod.example-internal.net, DNS:hueVIP,DNS:hbaseVIP,DNS:hiveVIP,DNS:sshVIP,DNS:hueVIP.example-internal.net,DNS:hbaseVIP.example-internal.net,DNS:hiveVIP.example-internal.net,DNS:sshVIP.example-internal.net
dataNode1 DNS:impalaVIP-prod.example-internal.net,DNS:solrVIP-prod.example-internal.net,DNS:impalaVIP,DNS:solrVIP,DNS:impalaVIP.example-internal.net,DNS:solrVIP.example-internal.net
```

 ### 3. 	Adding initial certs
After receiving the certs, rename them to .pem if needed and install them in the /opt/cloudera/security/setup/certs directory where the CSR files are.  The CSR files must be there or the CertToolkit will fail.
Install the Intermediate cert and Root CA in the /opt/cloudera/security/setup/ca-cert directory and make sure they have the .pem extension.
Make sure you have the complete chain. You can do this via:

 `openssl x509 –noout –text –in ROOT-CA-certname.pem`
 
Make sure all the nodes in the cluster are all actively participating and are not decommissioned or otherwise disabled.  If any python errors occurred, the script crashed and did not complete.  Remove any offending nodes from the cluster and re-run the command

  ####	Run the script to enable TLS:
Using this command:
`python certtoolkit.py  enable_tls`


 ### 4. 	Adding hosts later
If you need to add hosts later, make sure the host has the Cloudera manager agent installed and heartbeating to the Cloudera Manager Server host.
 *Put the new hostnames in a file called new_hosts.txt
 *Put the Subject Alternate Names mapping in a file called new_hosts_alt_names.txt and edit defaults.yaml to change the CERT_ALT_NAMES_FILE to match.
 *Rerun the script to generate CSRs: 
 *`python certtoolkit.py --new-hosts=new_hosts.txt prepare `
 *Send the new CSRs to get certs created.

When you get the certs back, copy them into the setup/certs directory and run
`python certtoolkit.py --new-hosts=new_hosts.txt enable_tls`

 ### 5. 	Troubleshooting
For the servers that will run TLS-enabled listeners, you can run this command to confirm that the certificate chain is acceptable to them:
openssl s_client –showcerts –connect master.example-internal.net:7183
Check out the troubleshooting section at the end for more ideas.

### 2. 	Kerberos
Kerberos is enabled via the wizard.  Prior to running the wizard, change the following configuration setting in Cloudera Manager under Administration->Settings.  If cross-realm trust (one-way or otherwise) will be needed, get the REALM names and respective kdc hosts for each one.  The fields will look something link this:
