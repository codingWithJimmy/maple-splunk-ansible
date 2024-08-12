#!/bin/bash
##########################################################################
########################### CUSTOMER VARIABLE ############################
##########################################################################
## Set this to the abbrevation of the customer's name.
CUSTOMER=""

##########################################################################
######################## SPLUNK RUNTIME VARIABLES ########################
##########################################################################
## Configure the Splunk admin account name.
SPLUNKADMIN=""
## Configure the password for the Splunk admin account.
ADMINPASS=''
## Configure the management port value used in this deployment.
MGMT_PORT=""
## Configure the location of the Splunk installation
SPLUNK_HOME=""
## Configure which version of Splunk you are installing
SPLUNK_VERSION=""

##########################################################################
###################### SPLUNK ARCHITECTURE VARIABLES #####################
##########################################################################
## Configure the hostname/IP of the deployment server.
DS_HOST=""
## Configure the hostname/IP of the license manager.
LM_HOST=""
## Comma delimmited list of indexers where data is to be sent. Ex. idx1.splunk.com:9997, idx2.splunk.com:9997
INDEXER_LIST=""

##########################################################################
####################### INDEXER CLUSTERING CONFIGS #######################
##########################################################################
## Configure whether indexer clustering will be used at your customer. The options are 'y'/'n'.
IDC=""
## Configure the number of indexers that will be deployed within the environment.
INDEXER_COUNT=""
## Configure the cluster manager hostname/IP.
CM_HOST=""
## Configure if the customer will be using indexer discovery. The options are 'y'/'n'.
DISCOVERY=""
## Configure the Pass4SymmKey for the cluster members.
CM_P4SK=''
## Configure if the customer is using indexer discovery.
CM_ID_P4SK=''
## Configure the cluster replication port.
CM_REP_PORT=""
## Configure the replication factor for the indexer cluster.
REP_FACTOR=""
## Configure the search factor for the indexer cluster.
SEARCH_FACTOR=""
## Configure a indexer cluster label.
IDC_LABEL=""

##########################################################################
########################### MULTISITE CONFIGS ############################
##########################################################################
## Configure if your customer will utilize multisite indexer clustering. The options are 'y'/'n'.
MULTISITE=""
## Configure the number of sites your customer will have.
SITE_COUNT=""
## Configure the site replication factor.
SITE_REP_FACTOR=""
## Configure the site search factor.
SITE_SEARCH_FACTOR=""
## Configure whether search heads will use search affinity. The options are 'y'/'n'.
SEARCH_AFFINITY=""
## Configure whether multisite clustering is possible in the future. The options are 'y'/'n'.
FUTURE_MS=""

##########################################################################
############################ INDEXING CONFIGS ############################
##########################################################################
## Configure the port that will be used for indexing.
INDEXING_PORT=""
## Configure the volume path where hot/warm indexed data will be stored.
HOTWARM_VOLUME=""
## Configure the maxmium size of the hot/warm volume.
HOTWARM_MAX=""
## Configure the volume path for cold storage on indexers.
COLD_VOLUME=""
## Configure the maxmium size of the cold volume.
COLD_MAX=""
## Configure the default retention in seconds.
RETENTION=""
## Configure the default maximum index size (MB) on indexers.
INDEX_MAX=""
## Configure if your customer will be accelerating data models. The options are 'y'/'n'.
SPLUNK_SUMMARIES=""
## Configure if your customer will be installing ES to create the ES indexes. The options are 'y'/'n'.
ES_INSTALL=""
## Configure if your customer will be installing ITSI to create the ITSI indexes. The options are 'y'/'n'.
ITSI_INSTALL=""
## Configure if your customer will be installing SAI to create the SAI indexes. The options are 'y'/'n'.
SAI_INSTALL=""
## Configure a HEC token for SAI collectd collection.
SAI_TOKEN=""
## Configure if your customer will be installing SC4S to create the SC4S indexes. The options are 'y'/'n'.
SC4S_INSTALL=""
## Configure a HEC token for SC4S.
SC4S_TOKEN=""
## Configure if your customer will be installing Phantom to create the indexes for receiving Phantom events. The options are 'y'/'n'.
PHANTOM_INSTALL=""
## Configure a HEC token for Phantom.
PHANTOM_TOKEN=""
## Configure a SPACE-delimited list of additional indexes that will be configured.
INDEX_LIST=""

##########################################################################
########################### SMARTSTORE CONFIGS ###########################
##########################################################################
## Configure if your customer will be utilizing SmartStore. The options are 'y'/'n'.
S2_INSTALL=""
## Configure the maximum size of the local cache on the indexers in MB.
S2_CACHE_MAX=""
## Configure the path to the S3 bucket for SmartStore. Ex. s3://bucket-name
S3_PATH=""
## Configure the S3 endpoint for SmartStore. Ex. https://s3.us-east-1.amazonaws.com
S3_ENDPOINT=""
## Configure the AWS access key for the IAM account.
#S3_ACCESS_KEY=""
## Configure the AWS secret key for the IAM account.
#S3_SECRET_KEY=""

##########################################################################
##################### SEARCH HEAD CLUSTERING CONFIGS #####################
##########################################################################
## Configure whether search head clustering will be used at your customer. The options are 'y'/'n'.
SHC=""
## Configure the deployer hostname/IP.
SHC_DEPLOYER_HOST=""
## Configure the Pass4SymmKey for the members.
SHC_P4SK=''
## Configure the search head cluster replication port.
SHC_REP_PORT=""
## Configure a search head cluster label.
SHC_LABEL=""
## Configure a SPACE-delimited list of the SHC member hostnames.
SHC_MEMBERS=""
