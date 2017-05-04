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

## Kerberos
Kerberos is enabled via the wizard.  Prior to running the wizard, change the following configuration setting in Cloudera Manager under Administration->Settings.  If cross-realm trust (one-way or otherwise) will be needed, get the REALM names and respective kdc hosts for each one.  The fields will look something link this:
###  1. Wizard
Property | Value 
| --- | --- |
Custom Kerberos Keytab Retrieval Script :| /opt/cloudera/security/keytabs/keytab_retrieval.sh 
Advanced Configuration Snippet (Safety Valve) for the Default Realm in krb5.conf :| kdc = kdchost.example-internal.net 
 Advanced Configuration Snippet (Safety Valve) for remaining krb5.conf | EXAMPLEDEV.COM = { 
|  | kdc = kdc1.example.com |  
|  | kdc = kdc2.example.com |  
|  |  } |  
|  |  FORESTROOT.COM = { |  
|  |  kdc = kdc3.forestroot.com |  
|  |  kdc = kdc4.forestroot.com |  
|  | } |  
|  |  EXAMPLEDR.EXAMPLE-INTERNAL.NET = { |  
|  |  kdc = kdc5.prodr.example-internal.net|  
|   | } |  
|   |  |  
|   | [domain_realm] |  
|   | .prod.example-internal.net = PROD.EXAMPLE-INTERNAL.NET |  
|   | .example.com = EXAMPLE.COM |  
|   | .prodr.example-internal.net = PRODR.EXAMPLE-INTERNAL.NET |  
|   | .forestroot.com = FORESTROOT.COM |  
|   | .example-internal.net = PROD.EXAMPLE-INTERNAL.NET |  
|   | [capaths] |  
|   | EXAMPLE.COM = { |  
|   |   PROD.EXAMPLE-INTERNAL.NET = FORESTROOT.COM |  
|    |  PROD.EXAMPLE-INTERNAL.NET = PRODR.EXAMPLE-INTERNAL.NET |  
|     | FORESTROOT.COM = . |  
|   | } |  
|   | PRODR. EXAMPLE-INTERNAL.COM = { |  
|   |  PROD.EXAMPLE-INTERNAL.NET = . |  
|   |   FORESTROOT.COM = . |  
|    |  EXAMPLE.COM = FORESTROOT.COM |  
|   | } |  
|   | FORESTROOT.COM = { |  
|    |  PRODR. EXAMPLE-INTERNAL.COM = . |  
|     | EXAMPLE.COM = . |  
|     | PROD. EXAMPLE-INTERNAL.COM = PRODR. EXAMPLE-INTERNAL.COM |  
|   | } |  
|   | PROD.EXAMPLE-INTERNAL.NET = { |  
|   |   EXAMPLE.COM = PRODR.EXAMPLE-INTERNAL.NET |  
|    |  EXAMPLE.COM = FORESTROOT.COM |  
|     | PRODR.EXAMPLE-INTERNAL.NET = . |  
|  |  } |  
 
 Even though the custom keytab retrieval script is being used, be sure to follow the pre-requisite to install the openldap-clients package with yum or the wizard will fail.
[ ] `yum install openldap-clients`
[ ] Start the wizard

After completing the wizard, add the following configuration to the HDFS service to map Kerberos principal names to lowercase and strip off the realm. In the case below, some users are coming in from EXAMPLE-INTERNAL.COM but some are also coming in from EXAMPLE.COM so we need to take care of them as well.

Property	|Value
| --- | --- | 
Additional Rules to Map Kerberos Principals to Short Names|RULE:[1:$1@$0](.*@\QQA.EXAMPLE-INTERNAL.NET\E$)s/@\QQA.EXAMPLE-INTERNAL.NET\E$//L
| | RULE:[2:$1@$0](.*@\QQA.EXAMPLE-INTERNAL.NET\E$)s/@\QQA.EXAMPLE-INTERNAL.NET\E$//L
| | RULE:[1:$1@$0](.*@\QEXAMPLE.COM\E$)s/@\QEXAMPLE.COM\E$//L
| | RULE:[2:$1@$0](.*@\QEXAMPLE.COM\E$)s/@\QEXAMPLE.COM\E$//L
| | DEFAULT

Because Kerberos was not enabled before the CertToolKit was run, several properties need to be changed in the HDFS service after running the Kerberos wizard.

Property	| Value
| --- | --- | 
Enable Data Transfer Encryption| [x]
Hadoop RPC Protection|Privacy
DataNode HTTP Web UI Port|Reset to default (50075)
DataNode Transceiver Port|Reset to default (50010)
Enable Kerberos Authentication for HTTP Web-Consoles|Checked

### 2.	YARN

[ ]  Determine if the following YARN properties must be configured depending on whether they want to enable spnego on their desktops

Property	| Value
| --- | --- | 
Enable Kerberos Authentication for HTTP Web-Consoles|Checked (or not)

### 3.	Hive

[ ] Set the encryption method for HiveServer2 to use SASL-QOP

Property	| Value
| --- | --- | 
HiveServer2 Advanced Configuration Snippet (Safety Valve) for hive-site.xml| ` <property>  <name>hive.server2.thrift.sasl.qop</name>  <value>auth-conf</value></property>`


[ ] Confirm beeline connectivity with a connection string similar to:
 ```
 beeline -u "jdbc:hive2://edgenode1.prod.example-internal.com:10000/default;saslQop=auth-conf;principal=hive/_HOST@PROD.EXAMPLE-INTERNAL.COM;ssl=true;sslTrustStore=/opt/cloudera/security/jks/truststore.jks"
 ```
 
### 4.	Debugging
If there is a need to troubleshoot, set these environment variables and try authenticating:
`export KRB5_TRACE=/tmp/krbtrace.log;`
`export JAVA_TOOL_OPTIONS=-Dsun.security.krb5.debug=true`

## LDAP
### 1.	Cloudera Manager

Property	| Value
| --- | --- | 
Authentication Backend Order|External then Database
External Authentication Type|Active Directory
LDAP URL|ldaps://KDC1.example.com
LDAP Bind User Distinguished Name|BINDACCOUNT
LDAP Bind Password|REDACTED
Active Directory Domain|EXAMPLE.COM
LDAP User Groups|ADGROUP_USER1, ADGROUP_USER2
LDAP Full Administrator Groups|ADGROUP_ADMINS

Since we are using LDAPS, there is a dependency on the default CA truststore located in /usr/java/latest/jre/lib/security/cacerts.  We will need to modify this and add our own ROOT and intermediate CAs.
On the CM host
 `cd /usr/java/latest/jre/lib/security`
Check it see if there is a file named jssccacerts
If it’s not there you need to add it:
`cp cacerts jssccacerts`
then import the CA certs (root and intermediate) to the jssccacerts truststore file.
`keytool -alias intermediate -import -file  /opt/cloudera/security/ca-certs/INTERMEDIATE.pem  -keystore jssccacerts`
(The password , is changeit)
`keytool -alias root -import -file  /opt/cloudera/security/ca-certs/Root_CA.pem  -keystore jssccacerts`
(The password , is changeit)
Verify if you want:
`/usr/java/latest/bin/keytool -list -v -keystore jssecacerts | grep -v SHA | grep –I example`
Then restart the Cloudera manager server

If you see this error:
PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target. 
Look at jssecacerts in `/usr/java/latest/jre/lib/security/`. The problem is that the root CA cannot be found.  
Also try:
`openssl s_client –showcerts –connect ldaps.example.com:636 `
Look at the root CAs and make sure they match the ones you’ve been given.




3.2	Cloudera Navigator
Property	|Value
| --- | --- | 
Authentication Backend Order|External then Cloudera Manager
External Authentication Type|Active Directory
LDAP URL|ldaps://KDC1.example.com
LDAP Bind User Distinguished Name|BINDACCOUNT
LDAP Bind Password|REDACTED
Active Directory Domain|EXAMPLE.COM
LDAP Group Search Base|OU=AccessGroups,DC=EXAMPLE,DC=COM
LDAP Group Search Filter For Logged In User|(member={0})
LDAP Groups Search Filter|(&(objectClass=group)(cn=*{0}*))

3.3	Hue
Property	|Value
| --- | --- | 
Authentication Backend|desktop.auth.backend.LdapBackend
LDAP URL|ldaps://KDC1.example.com
Active Directory Domain|EXAMPLE.COM
LDAP Server CA Certificate|
|
Use Search Bind Authentication|Checked
Create LDAP users on login|Checked
LDAP Search Base|DC=EXAMPLE,DC=COM
LDAP Bind User Distinguished Name|BINDACCOUNT
LDAP Bind Password|REDACTED
LDAP User Filter
|(objectClass=user)
LDAP Username Attribute
|sAMAccountName
LDAP Group Filter|(objectClass=group)
LDAP Group Name Attribute|cn

3.4	Impala w/ LDAP
Impala was not written in Java, so it does not use /usr/java/latest/jre/lib/security/jssecacerts when authenticating with LDAP.
It uses the ca-certs PEM files in /opt/cloudera/security/truststore/ca-truststore.pem
The ROOT and intermediate certificates that signed the LDAPs server’s certificate need to be included in /opt/cloudera/security/truststore/ca-truststore.pem. So if you had to modify jssecacerts for ldap, you’ll need to modify /opt/cloudera/security/truststore/ca-truststore.pem as well.
This new version of the truststore will need to be copied to all the nodes in the cluster since every impalad will need to talk to the LDAP server at some point.

Property	|Value
| --- | --- | 
Enable LDAP Authentication|Checked
LDAP URL|ldaps://KDC1.example.com
Active Directory Domain|EXAMPLE.COM
LDAP Server CA Certificate|/opt/cloudera/security/truststore/ca-truststore.pem

3.5	Hive
Because the production LDAP server’s TLS certificate is signed by a different root CA, We had to push out the updated truststore.jks and jssecacerts to all the hosts. 

Property	|Value
| --- | --- | 
Enable LDAP Authentication|Checked
LDAP URL|ldaps://KDC1.example.com
Active Directory Domain|EXAMPLE.COM
LDAP Server CA Truststore|/opt/cloudera/security/truststore/ca-truststore.pem

4	Cluster Service Over-the-Wire Encryption
4.1	HBase
Property	|Value
| --- | --- | 
HBase Thrift Authentication|auth-conf
HBase REST Authentication|Kerberos
HBase Transport Security|Privacy
Web UI TLS/SSL Encryption Enabled|Checked
HBase TLS/SSL Server JKS Keystore File Location|/opt/cloudera/security/jks/keystore.jks
HBase TLS/SSL Server JKS Keystore File Password|REDACTED
HBase TLS/SSL Server JKS Keystore Key Password|REDACTED
Enable TLS/SSL for HBase REST Server|Checked
HBase REST Server TLS/SSL Server JKS Keystore File Location|/opt/cloudera/security/jks/keystore.jks
HBase REST Server TLS/SSL Server JKS Keystore File Password|REDACTED
HBase REST Server TLS/SSL Server JKS Keystore Key Password|REDACTED
Enable TLS/SSL for HBase Thrift Server over HTTP|Checked
HBase Thrift Server over HTTP TLS/SSL Server JKS Keystore File Location|/opt/cloudera/security/jks/keystore.jks
HBase Thrift Server over HTTP TLS/SSL Server JKS Keystore File Password|REDACTED
HBase Thrift Server over HTTP TLS/SSL Server JKS Keystore Key Password|REDACTED

4.2	HDFS
Property	|Value
| --- | --- | 
Enable Kerberos Authentication for HTTP Web-Consoles|Checked
DataNode Data Transfer Protection|privacy
DataNode Transceiver Port|50010
Enable Access Control Lists|Checked
Hadoop RPC Protection|privacy
Enable Data Transfer Encryption|Checked
Hadoop TLS/SSL Enabled|Checked
Hadoop TLS/SSL Server Keystore File Location|/opt/cloudera/security/jks/keystore.jks
Hadoop TLS/SSL Server Keystore File Password|REDACTED
Hadoop TLS/SSL Server Keystore Key Password|REDACTED
Cluster-Wide Default TLS/SSL Client Truststore Location|/opt/cloudera/security/jks/truststore.jks
Cluster-Wide Default TLS/SSL Client Truststore Password|changeit
Enable TLS/SSL for HttpFS|Checked
HttpFS TLS/SSL Server JKS Keystore File Location|/opt/cloudera/security/jks/keystore.jks
HttpFS TLS/SSL Server JKS Keystore File Password|REDACTED
HttpFS TLS/SSL Certificate Trust Store File|/opt/cloudera/security/jks/truststore.jks
HttpFS TLS/SSL Certificate Trust Store Password|REDACTED

4.3	Hive
Property	|Value
| --- | --- | 
Enable TLS/SSL for HiveServer2|Checked
HiveServer2 TLS/SSL Server JKS Keystore File Location|/opt/cloudera/security/jks/keystore.jks
HiveServer2 TLS/SSL Server JKS Keystore File Password|REDACTED
HiveServer2 TLS/SSL Certificate Trust Store File|/opt/cloudera/security/jks/truststore.jks
HiveServer2 TLS/SSL Certificate Trust Store Password|REDACTED
Enable TLS/SSL for HiveServer2 WebUI|Checked
HiveServer2 WebUI TLS/SSL Server JKS Keystore File Password|REDACTED
HiveServer2 WebUI TLS/SSL Server JKS Keystore File Location|/opt/cloudera/security/jks/keystore.jks

4.4	Impala
Property	|Value
| --- | --- | 
Enable TLS/SSL for Impala|Checked
Impala TLS/SSL Server Certificate File (PEM Format)|/opt/cloudera/security/x509/cert.pem
Impala TLS/SSL Server Private Key File (PEM Format)|/opt/cloudera/security/x509/key.pem
Impala TLS/SSL Private Key Password|REDACTED
Impala TLS/SSL CA Certificate|/opt/cloudera/security/ca-certs/ root-ca.pem
Catalog Server Webserver TLS/SSL Server Certificate File (PEM Format)|/opt/cloudera/security/x509/cert.pem
Catalog Server Webserver TLS/SSL Server Private Key File (PEM Format)|/opt/cloudera/security/x509/key.pem
Catalog Server Webserver TLS/SSL Private Key Password|REDACTED
Disk Spill Encryption|Checked
Impala Daemon Webserver TLS/SSL Server Certificate File (PEM Format)|/opt/cloudera/security/x509/cert.pem
Impala Daemon Webserver TLS/SSL Server Private Key File (PEM Format)|/opt/cloudera/security/x509/key.pem
Impala Daemon Webserver TLS/SSL Private Key Password|REDACTED
StateStore Webserver TLS/SSL Server Certificate File (PEM Format)|/opt/cloudera/security/x509/cert.pem
StateStore Webserver TLS/SSL Server Private Key File (PEM Format)|/opt/cloudera/security/x509/key.pem
StateStore Webserver TLS/SSL Private Key Password|REDACTED

4.5	Kafka
Property		|Value	
| --- | --- | 
Enable TLS/SSL for Kafka Broker|Checked
Kafka Broker TLS/SSL Server JKS Keystore File Location|/opt/cloudera/security/jks/keystore.jks
Kafka Broker TLS/SSL Server JKS Keystore File Password|REDACTED
Kafka Broker TLS/SSL Server JKS Keystore Key Password|REDACTED
Kafka Broker TLS/SSL Certificate Trust Store File|/opt/cloudera/security/jks/truststore.jks
Kafka Broker TLS/SSL Certificate Trust Store Password|REDACTED

4.6	Key-Value Store
Property	|Value	
| --- | --- | 
HBase Indexer TLS/SSL Certificate Trust Store File|/opt/cloudera/security/jks/truststore.jks
HBase Indexer TLS/SSL Certificate Trust Store Password|REDACTED

4.7	Oozie
Property	|Value	
| --- | --- | 
Enable TLS/SSL for Oozie |Checked
Oozie TLS/SSL Server JKS Keystore File Location|/opt/cloudera/security/jks/keystore.jks
Oozie TLS/SSL Server JKS Keystore File Password|REDACTED
Oozie TLS/SSL Certificate Trust Store File|/opt/cloudera/security/jks/truststore.jks
Oozie TLS/SSL Certificate Trust Store Password|REDACTED

4.8	Solr
Property	|Value	
| --- | --- | 
Enable TLS/SSL for Solr|Checked
Solr TLS/SSL Server JKS Keystore File Location|/opt/cloudera/security/jks/keystore.jks
Solr TLS/SSL Server JKS Keystore File Password|REDACTED
Solr TLS/SSL Certificate Trust Store File|/opt/cloudera/security/jks/truststore.jks
Solr TLS/SSL Certificate Trust Store Password|REDACTED

4.9	YARN
Property	|Value
| --- | --- | 
Hadoop TLS/SSL Server Keystore File Location|/opt/cloudera/security/jks/keystore.jks
Hadoop TLS/SSL Server Keystore File Password|REDACTED
Hadoop TLS/SSL Server Keystore Key Password|REDACTED
Enable Kerberos Authentication for HTTP Web-Consoles|Checked
TLS/SSL Client Truststore File Location|/opt/cloudera/security/jks/truststore.jks
TLS/SSL Client Truststore File Password|REDACTED

5	Sentry
Installed service on host master1.example-internal.net.  Make sure the database-connector-java.jar is  a supported version.  

5.1	HDFS Sentry Configuration
Property	|Value	
| --- | --- | 
Enable Sentry Synchronization|Checked
Sentry Synchronization Path Prefixes|/user/hive/warehouse
/otherdata
Sentry Admin group|LDAP_admingroup

5.2	Sentry Configuration
Property	|Value	
| --- | --- | 
Sentry Admin group +=|LDAP_admingroup


Add Sentry Service dependencies for Hive, Impala, Solr, Hue, Kafka
On HiveServer2 make sure Impersonation is disabled.
Log into beeline and set up the DBA role for the sentry admin group
create role platform_admin;
grant all on server server1 to platform_admin; grant role platform_admin to group LDAP_admingroup;
6	HDFS Encryption at Rest
HDFS transparent disk encryption should be configured using the Cloudera Manager wizard.  Prior to running the wizard, make sure the jssecacerts file from /user/java/latest/jre/lib/security/jssecacerts is copied to the same location on both KMS Proxy hosts.
Also make sure the nodes that will be the key trustee server are NOT part of the CDH cluster.  They will be added into their own cluster.
Make sure the KEYTRUSTEE SERVER parcel has not been distributed on the CDH cluster. Remove it if has.  Otherwise the wizard will be confused and won’t ask you to create a dedicated cluster for the key trustees.
Make sure the CDH parcel has not been distributed to a KeyTrustee cluster if you have made one already.
Prior to starting the wizard, make sure that the hosts that will run the key trustee role instances have the key trustee server parcel downloaded/distributed and activated.
To do this, copy KEYTRUSTEE_SERVER-5.10.0-1.keytrustee5.10.0.p0.26-el7.parcel and KEYTRUSTEE_SERVER-5.10.0-1.keytrustee5.10.0.p0.26-el7.parcel.sha to the CM host:/opt/cloudera/parcel-repo and then in CM parcels page click the “check for new parcels” button.
Identify the hosts that will perform the roles:
 
Continue with the wizard to add the cluster, install the parcels and select the hosts.
Continue to follow the steps in the wizard:
  


Following the wizard:
 

Before the rsync step you may need to scp the CM host’s id_rsa* to root@keytrustee2:.ssh/

 
Figure 1 PROD



Then ssh to the other keytrustee host and init
 


6.1	KeyTrustee Server Configuration Settings
These settings were changed from the default during the wizard installation.
Property	|Value	
| --- | --- | 
Active Key Trustee Server TLS/SSL Server Private Key File (PEM Format)|/opt/cloudera/security/x509/key.pem	
Active Key Trustee Server TLS/SSL Server Certificate File (PEM Format)|/opt/cloudera/security/x509/cert.pem
Active Key Trustee Server TLS/SSL Server CA Certificate (PEM Format)|/opt/cloudera/security/truststore/truststore.pem
Active Key Trustee Server TLS/SSL Private Key Password|REDACTED
Passive Key Trustee Server TLS/SSL Server Private Key File (PEM Format)|/opt/cloudera/security/x509/key.pem
Passive Key Trustee Server TLS/SSL Server Certificate File (PEM Format)|/opt/cloudera/security/x509/cert.pem
Passive Key Trustee Server TLS/SSL Server CA Certificate (PEM Format)|/opt/cloudera/security/truststore/truststore.pem
Passive Key Trustee Server TLS/SSL Private Key Password|REDACTED

6.2	KMS Proxy Configuration Settings
These settings were changed from the default during the wizard installation.  The Key Trustee Organization name is QA. 
Use the Key Trustee Servers that you just created 
Refer to the server role assignment spreadsheet to determine the new KMS hosts.
When the wizard asks for an ORG name: PROD (Verify what the value is for DR….)

```[root@keytrustee1 ~]# keytrustee-orgtool add -n PROD -c root@localhost
Dropped privileges to keytrustee
2017-04-12 11:56:44,587 - keytrustee.server.orgtool - INFO - Adding organization to database
2017-04-12 11:56:44,590 - keytrustee.server.orgtool - INFO - Initializing random secret
[root@keytrustee1 ~]# keytrustee-orgtool list
Dropped privileges to keytrustee
{
    "PROD": {
        "auth_secret": "REDACTED",
        "contacts": [
            "root@localhost"
        ],
        "creation": "2017-04-12T11:56:44",
        "expiration": "9999-12-31T18:59:59",
        "key_info": null,
        "name": "PROD",
        "state": 0,
        "uuid": "IPs2guXk0spuweeweboCpn9VA3zXFKhrbL1sPITpp"
    }
} 
```
Property	|Value	
| --- | --- | 
Enable TLS/SSL for Key Management Server Proxy|Checked
Key Management Server Proxy TLS/SSL Server JKS Keystore File Location|/opt/cloudera/security/jks/keystore.jks
Key Management Server Proxy TLS/SSL Server JKS Keystore File Password|
Key Management Server Proxy TLS/SSL Certificate Trust Store File|/opt/cloudera/security/jks/truststore.jks
Key Management Server Proxy TLS/SSL Certificate Trust Store Password|
The following KMS ACLs were pasted into the configuration input text box in the wizard:
```
<property><name>hadoop.kms.acl.CREATE</name><value>nobody LDAP_admingroup</value><description>
    ACL for create-key operations.
    If the user is not in the GET ACL, the key material is not returned
    as part of the response.
  </description></property><property><name>hadoop.kms.acl.DELETE</name><value>nobody LDAP_admingroup</value><description>
    ACL for delete-key operations.
  </description></property><property><name>hadoop.kms.acl.ROLLOVER</name><value>nobody LDAP_admingroup</value><description>
    ACL for rollover-key operations.
    If the user does is not in the GET ACL, the key material is not returned
    as part of the response.
  </description></property><property><name>hadoop.kms.acl.GET</name><value></value><description>
    ACL for get-key-version and get-current-key operations.
  </description></property><property><name>hadoop.kms.acl.GET_KEYS</name><value>nobody LDAP_admingroup</value><description>
    ACL for get-keys operations.
  </description></property><property><name>hadoop.kms.acl.SET_KEY_MATERIAL</name><value></value><description>
    Complementary ACL for CREATE and ROLLOVER operations to allow the client
    to provide the key material when creating or rolling a key.
  </description></property><property><name>hadoop.kms.acl.GENERATE_EEK</name><value>hdfs supergroup</value><description>
    ACL for generateEncryptedKey CryptoExtension operations.
  </description></property><property><name>hadoop.kms.blacklist.CREATE</name><value>hdfs supergroup</value></property><property><name>hadoop.kms.blacklist.DELETE</name><value>hdfs supergroup</value></property><property><name>hadoop.kms.blacklist.ROLLOVER</name><value>hdfs supergroup</value></property><property><name>hadoop.kms.blacklist.GET</name><value>*</value></property><property><name>hadoop.kms.blacklist.GET_KEYS</name><value></value></property><property><name>hadoop.kms.blacklist.SET_KEY_MATERIAL</name><value>*</value></property><property><name>hadoop.kms.blacklist.DECRYPT_EEK</name><value></value></property><property><name>keytrustee.kms.acl.UNDELETE</name><value></value><description>
    ACL that grants access to the UNDELETE operation on all keys.
    Only used by Key Trustee KMS.
  </description></property><property><name>keytrustee.kms.acl.PURGE</name><value></value><description>
    ACL that grants access to the PURGE operation on all keys.
    Only used by Key Trustee KMS.
  </description></property><property><name>default.key.acl.MANAGEMENT</name><value></value><description>
    Default ACL that grants access to the MANAGEMENT operation on all keys.
  </description></property><property><name>default.key.acl.GENERATE_EEK</name><value></value><description>
    Default ACL that grants access to the GENERATE_EEK operation on all keys.
  </description></property><property><name>default.key.acl.DECRYPT_EEK</name><value>*</value><description>
    Default ACL that grants access to the DECRYPT_EEK operation on all keys.
  </description></property><property><name>default.key.acl.READ</name><value>nobody hive</value><description>
    Default ACL that grants access to the READ operation on all keys.
  </description></property><property><name>whitelist.key.acl.MANAGEMENT</name><value>nobody LDAP_admingroup</value><description>
    Whitelist ACL for MANAGEMENT operations for all keys.
  </description></property><property><name>whitelist.key.acl.READ</name><value>hdfs supergroup</value><description>
    Whitelist ACL for READ operations for all keys.
  </description></property><property><name>whitelist.key.acl.GENERATE_EEK</name><value>hdfs supergroup</value><description>
    Whitelist ACL for GENERATE_EEK operations for all keys.
  </description></property><property><name>whitelist.key.acl.DECRYPT_EEK</name><value>nobody LDAP_admingroup</value><description>
    Whitelist ACL for DECRYPT_EEK operations for all keys.
  </description></property><property><name>key.acl.hive-key.DECRYPT_EEK</name><value>hive hive</value><description>
    Gives the hive user and the hive group access to the key named "hive-key".
    This allows the hive service to read and write files in /user/hive/.
    Also note that the impala user ought to be a member of the hive group
    in order to enjoy this same access.
  </description></property><property><name>key.acl.hive-key.READ</name><value>hive hive</value><description>
    Required because hive compares key strengths when joining tables.
  </description></property><property><name>key.acl.hbase-key.DECRYPT_EEK</name><value>hbase hbase</value><description>
    Gives the hbase user and hbase group access to the key named "hbase-key".
    This allows the hbase service to read and write files in /hbase.
  </description></property><property><name>key.acl.solr-key.DECRYPT_EEK</name><value>solr solr</value><description>
    Gives the solr user and solr group access to the key named "solr-key".
    This allows the solr service to read and write files in /solr.
  </description></property><property><name>key.acl.mapred-key.DECRYPT_EEK</name><value>mapred,yarn hadoop</value><description>
    Gives the mapred user and mapred group access to the key named "mapred-key".
    This allows mapreduce to read and write files in /user/history.
    This is required by YARN.
  </description></property><property><name>key.acl.hue-key.DECRYPT_EEK</name><value>oozie,hue oozie,hue</value><description>
    Gives the appropriate users and groups access to the key named "hue-key".
    This allows hue and oozie to read and write files in /user/hue.
    Oozie is required here because it will attempt to access workflows in
    /user/hue/oozie/workspaces.
  </description></property>
  ```
 ## 6. 	HDFS
Make sure KMS Service has “Key Trustee KMS” selected
Make sure the KMS jks files have the root and intermediate certs imported
### 6.4	Encryption Zones
Create the encryption zone keys
hadoop key create datakey
hadoop key create hbase
hadoop key create solr


Create the encryption zones
hdfs crypto -createZone -path /data -keyName datakey 
hdfs crypto -createZone -path /keystore -keyName keystore_key
Because HBase and Solr were already initialized, those services will have to be stopped and because there was no data in the existing directories, the existing /hbase and /solr directories were renamed to be /hbase_orig and /solr_orig .  /hbase and /solr were then created and the encryption zones were created. Then the contents of the orig directories were copied over and then the orig directories were removed.
The following commands created the encryption zones
hdfs crypto -createZone -path /hbase -keyName hbase_key
hdfs crypto -createZone -path /solr -keyName solr_key
hdfs crypto -createZone -path /user/hive/warehouse -keyName datakey 

  ### 6.5	Missing encryption keys
During the installation process, it was discovered that some of the keys were no longer showing up with the Hadoop key –list command.
Cloudera support ask PNC to turn off each KMS and retry the listing.  When lbdp34wbn.prod.pncint.net was the active KMS the keys appeared.  But it did not appear when lbdp34xbn.prod.pncint.net.
The reason for this was because due to an installation error, the two KMSs had different identities from the perspective of the KTS.

This was confirmed by ssh’ing into both KMSs and running this command and getting different results.
```
gpg --fingerprint --homedir /var/lib/kms-keytrustee/keytrustee/.keytrustee

# gpg --fingerprint --homedir /var/lib/kms-keytrustee/keytrustee/.keytrustee

/var/lib/kms-keytrustee/keytrustee/.keytrustee/pubring.gpg
----------------------------------------------------------
pub   4096R/70133D83 2016-02-12
      Key fingerprint = F2D1 24AA 220C 9748 6BDC  B8F7 ACDF 423A 7013 3D83
uid                  keytrustee (keytrustee Server Key) <keytrustee@keytrustee-1.lab.atx.cloudera.com>
sub   4096R/F3A1C2CF 2016-02-12

pub   4096R/89A8D7C1 2016-03-15
      Key fingerprint = D603 FE64 A092 861B E359  256D D30A 6A13 89A8 D7C1
uid                  keytrustee (client) <kms@kms-1.lab.atx.cloudera.com>
sub   4096R/CF52690D 2016-03-15
```
The solution was to replicate the signature on one of the KMSs onto the other one so they would be perceived as the same identity by the KTS.  The first step was to first determine if any of the keys were critical and if there were critical keys on both KMSs. 
In this case there is only one critical key on one of the KMS instances.
The process to correct this involved the following steps:
1.	Shut down both KMSs
2.	Ssh onto the ‘good’ KMS
3.	Rsync the signature files onto the ‘bad’ one
`rsync -avP /var/lib/kms-keytrustee/keytrustee/.keytrustee/ root@<bad one>:/var/lib/kms-keytrustee/keytrustee/.keytrustee/`
4.	Confirm the sigs are the same
`gpg --fingerprint --homedir /var/lib/kms-keytrustee/keytrustee/.keytrustee`

5.	Restart the KMS

7	Appendix

7.1	Troubleshooting
Message: [24/Apr/2017 07:05:31 -0700] WARNING  Caught LDAPError while authenticating jprosser: SERVER_DOWN({'info': "TLS error -8179:Peer's Certificate issuer is not recognized.", 'desc': "Can't contact LDAP server"},)


 
