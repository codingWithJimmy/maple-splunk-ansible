#!/bin/bash
##/usr/local/bin/bash

## Mac Compatible Bash
## If you want to do this locally on a Macbook, you'll need to upgrade your
## version of Bash installed on the Mac since anything before Bash 4.0 won't
## work with this script due to how commands are being used.
## https://clubmate.fi/upgrade-to-bash-4-in-mac-os-x/

## After upgrading, change line 1 to: '#!/usr/local/bin/bash'

## Script developed by Jimmy Maple - Splunk Professional Services

## This script was developed to make the generation and dissemination of Splunk
## Professional Services base apps for Splunk deployments quick and simple.
## The script is designed to generate apps for the following Splunk roles:
## - Search Head (Stand alone and Cluster member)
## - Indexer (Stand alone and Cluster member)
## - Cluster manager
## - Forwarders
## - Index specific configurations including SmartStore and multisite clustering

## Note the indexer cluster configurations, by default, configures the indexers to
## be multisite. However, the indexers are all configured to be site 1. This is to
## future-proof the cluster to allow for multisite expansion in the future.

## Another note when using this script:
## The indexes for Splunk-supported apps may not be consistent with the current stable
## version of those apps. Double-check that all the required indexes have been created
## after the base apps are created. Updated versions can sometimes contain newer indexes.

## Current directory variable. Allows the script to run anywhere and create the apps next to the script
PWD=$(pwd)
ORGANIZATION=$1

call_variables() {
	if [ ! -z "${ORGANIZATION}" ]; then
		if [ ! -d "${PWD}/${ORGANIZATION}" ]; then
			mkdir "${PWD}/${ORGANIZATION}"
		fi
		if [ -f "${PWD}/${ORGANIZATION}_variables.sh" ]; then
			source "${PWD}/${ORGANIZATION}_variables.sh"
			SPLUNK_VERSION=$(echo ${SPLUNK_VERSION} | sed 's|\.||g')
		else
			echo "------------------------------------------------------------------"
			read -p 'Enter organization configuration: ' ORGANIZATION
			if [ -f "${PWD}/${ORGANIZATION}_variables.sh" ]; then
				source "${PWD}/${ORGANIZATION}_variables.sh"
				SPLUNK_VERSION=$(echo ${SPLUNK_VERSION} | sed 's|\.||g')
			else
				echo "No variables file for \"${ORGANIZATION}\" has been generated. Re-run the script and generate the variables."
				exit
			fi
		fi
	else
		if [ -f "${PWD}/${ORGANIZATION}_variables.sh" ]; then
			source "${PWD}/${ORGANIZATION}_variables.sh"
			SPLUNK_VERSION=$(echo ${SPLUNK_VERSION} | sed 's|\.||g')
		else
			echo "------------------------------------------------------------------"
			echo "To configure multiple environments, you can configure the organization with the environment to generate a separete set of apps."
			echo "Example: 'splunk_prod' for Splunk's Production environment and 'splunk_test' for Splunk's Test environment"
			echo "------------------------------------------------------------------"
			read -p 'Enter organization configuration: ' ORGANIZATION
			if [ -f "${PWD}/${ORGANIZATION}_variables.sh" ]; then
				source "${PWD}/${ORGANIZATION}_variables.sh"
				SPLUNK_VERSION=$(echo ${SPLUNK_VERSION} | sed 's|\.||g')
			else
				echo "No variables file for \"${ORGANIZATION}\" has been generated. Re-run the script and generate the variables."
				exit
			fi
		fi
	fi
}

generate_variables() {
	echo "------------------------------------------------------------------"
	echo "This option is meant to allow the user to generate a file of all the
necessary variables needed to run this script automatically. Currently there
are over 50 variables to be configured and they can be very grainular. Please have
as much deployment information available to fill in the file. If you don't have
a specific piece of information, you can simply hit enter and skip that input.
It can be added to the file after-the-fact. Your organization may experience
inconsistent results if some of the values are not present. Be sure to inspect app
settings prior to deployment."
	echo "------------------------------------------------------------------"
	read -p 'Are you ready to begin?: [Y/N] ' GET_VARIABLES
	case "$GET_VARIABLES" in
		[Yy]* )
			if [ ! -z "${ORGANIZATION}" ]; then
				if [ -f "${PWD}/${ORGANIZATION}_variables.sh" ]; then
					source "${PWD}/${ORGANIZATION}_variables.sh"
					echo "------------------------------------------------------------------"
					echo "${ORGANIZATION}_variables.sh script found. Expanding existing variables..."
				fi
			else
				echo "------------------------------------------------------------------"
				echo "To configure multiple environments, you can configure the organization with the environment to generate a separete set of apps."
				echo "Example: 'splunk_prod' for Splunk's Production environment and 'splunk_test' for Splunk's Test environment"
				echo "------------------------------------------------------------------"
				read -p 'Enter organization configuration: ' ORGANIZATION
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$SPLUNKADMIN" ]; then
				read -er -p 'Enter username of Splunk admin account: ' -i "$SPLUNKADMIN" SPLUNKADMIN
			else
				read -er -p 'Enter username of Splunk admin account: ' -i "admin" SPLUNKADMIN
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$ADMINPASS" ]; then
				echo "Current password for $SPLUNKADMIN: $ADMINPASS"
				echo "It is recommended to change it manually in \"${ORGANIZATION}_variables.sh\" if needed."
			else
				read -s -p "Enter password for the Splunk account \"$SPLUNKADMIN\": " ADMINPASS
			printf "\n"
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$MGMT_PORT" ]; then
				read -er -p 'Enter the management port that will be used in the deployment: ' -i "$MGMT_PORT" MGMT_PORT
			else
				read -er -p 'Enter the management port that will be used in the deployment: ' -i "8089" MGMT_PORT
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$SPLUNK_HOME" ]; then
				read -er -p 'Enter the installation directory of Splunk: ' -i "$SPLUNK_HOME" SPLUNK_HOME
			else
				read -er -p 'Enter the installation directory of Splunk: ' -i "/opt" SPLUNK_HOME
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$SPLUNK_VERSION" ]; then
				echo "Example: 8.0.5"
				read -er -p 'Enter the version of Splunk this will be installed: ' -i "$SPLUNK_VERSION" SPLUNK_VERSION
			else
				echo "Example: 8.0.5"
				read -er -p 'Enter the version of Splunk this will be installed: ' SPLUNK_VERSION
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$LM_HOST" ]; then
				read -er -p 'Enter the hostname/IP of the license manager: ' -i "$LM_HOST" LM_HOST
			else
				read -p 'Enter the hostname/IP of the license manager: ' LM_HOST
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$DS_HOST" ]; then
				read -er -p 'Enter hostname/IP of the deployment server: ' -i "$DS_HOST" DS_HOST
			else
				read -p 'Enter hostname/IP of the deployment server: ' DS_HOST
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$INDEXER_COUNT" ]; then
				read -er -p 'Enter the number of indexers in the deployment: ' -i "$INDEXER_COUNT" INDEXER_COUNT
			else
				read -p 'Enter the number of indexers in the deployment: ' INDEXER_COUNT
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$INDEXING_PORT" ]; then
				read -er -p 'Enter the port on which the indexers will receive data: ' -i "$INDEXING_PORT" INDEXING_PORT
			else
				read -p 'Enter the port on which the indexers will receive data: ' INDEXING_PORT
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$HOTWARM_VOLUME" ]; then
				read -er -p 'Enter the volume path for hot/warm storage on indexers: ' -i "$HOTWARM_VOLUME" HOTWARM_VOLUME
			else
				read -p 'Enter the volume path for hot/warm storage on indexers: ' HOTWARM_VOLUME
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$HOTWARM_MAX" ]; then
				read -er -p 'Enter the maxmium size of the hot/warm volume (MB): ' -i "$HOTWARM_MAX" HOTWARM_MAX
			else
				read -p 'Enter the maxmium size of the hot/warm volume: ' HOTWARM_MAX
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$COLD_VOLUME" ]; then
				read -er -p 'Enter the volume path for cold storage on indexers: ' -i "$COLD_VOLUME" COLD_VOLUME
			else
				read -p 'Enter the volume path for cold storage on indexers: ' COLD_VOLUME
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$COLD_MAX" ]; then
				read -er -p 'Enter the maxmium size of the cold volume (MB): ' -i "$COLD_MAX" COLD_MAX
			else
				read -p 'Enter the maxmium size of the cold volume: ' COLD_MAX
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$INDEX_MAX" ]; then
				read -er -p 'Enter the default size for each index: ' -i "$INDEX_MAX" INDEX_MAX
			else
				read -p 'Enter the default size for each index: ' INDEX_MAX
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$SPLUNK_SUMMARIES" ]; then
				read -er -p 'Will your organization be accelerating data models? [Y/N] ' -i "$SPLUNK_SUMMARIES" SPLUNK_SUMMARIES
			else
				read -p 'Will your organization be accelerating data models? [Y/N] ' SPLUNK_SUMMARIES
			fi
			echo "------------------------------------------------------------------"
			echo "Seconds Conversion Cheat Sheet
   86400 = 1 day
  604800 = 1 week
 2592000 = 1 month
31536000 = 1 year"
			echo "------------------------------------------------------------------"
			if [ ! -z "$RETENTION" ]; then
				read -er -p 'Enter the default retention in seconds: ' -i "$RETENTION" RETENTION
			else
				read -p 'Enter the default retention in seconds: ' RETENTION
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$S2_INSTALL" ]; then
				read -er -p 'Will your organization be utilizing SmartStore? [Y/N]: ' -i "$S2_INSTALL" S2_INSTALL
			else
				read -p 'Will your organization be utilizing SmartStore? [Y/N]: ' S2_INSTALL
			fi
			case "$S2_INSTALL" in
				[Yy]* )
					echo "------------------------------------------------------------------"
					if [ ! -z "$S2_CACHE_MAX" ]; then
						read -er -p 'What is the maximum size (in MB) of the local cache storage? : ' -i "$S2_CACHE_MAX" S2_CACHE_MAX
					else
						read -p 'What is the maximum size (in MB) of the local cache storage? : ' S2_CACHE_MAX
					fi
					echo "------------------------------------------------------------------"
					if [ ! -z "$S3_PATH" ]; then
						read -er -p 'Enter the full path to the S3 bucket: ' -i "$S3_PATH" S3_PATH
					else
						echo "Ex. s3://bucket-name"
						read -p 'Enter the full path to the S3 bucket: ' S3_PATH
					fi
					echo "------------------------------------------------------------------"
					if [ ! -z "$S3_ENDPOINT" ]; then

						read -er -p 'Enter the remote endpoint of the S3 bucket: ' -i "$S3_ENDPOINT" S3_ENDPOINT
					else
						echo "Ex. https://s3.us-east-1.amazonaws.com"
						read -p 'Enter the remote endpoint of the S3 bucket: ' S3_ENDPOINT
					fi
					echo "------------------------------------------------------------------"
					if [ ! -z "$S3_ACCESS_KEY" ]; then
						read -er -p 'Enter the access key of the S3 bucket: ' -i "$S3_ACCESS_KEY" S3_ACCESS_KEY
					else
						read -p 'Enter the access key of the S3 bucket: ' S3_ACCESS_KEY
					fi
					echo "------------------------------------------------------------------"
					if [ ! -z "$S3_SECRET_KEY" ]; then
						read -er -p 'Enter the secret key of the S3 bucket: ' -i "$S3_SECRET_KEY" S3_SECRET_KEY
					else
						read -p 'Enter the secret key of the S3 bucket: ' S3_SECRET_KEY
					fi
					;;
				* )
			esac
			echo "------------------------------------------------------------------"
			if [ ! -z "$ES_INSTALL" ]; then
				read -er -p 'Will your organization be installing Enterprise Security? [Y/N] ' -i "$ES_INSTALL" ES_INSTALL
			else
				read -p 'Will your organization be installing Enterprise Security? [Y/N] ' ES_INSTALL
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$ITSI_INSTALL" ]; then
				read -er -p 'Will your organization be installing ITSI? [Y/N] ' -i "$ITSI_INSTALL" ITSI_INSTALL
			else
				read -p 'Will your organization be installing ITSI? [Y/N] ' ITSI_INSTALL
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$SC4S_INSTALL" ]; then
				read -er -p 'Will your organization be installing SC4S? [Y/N] ' -i "$SC4S_INSTALL" SC4S_INSTALL
			else
				read -p 'Will your organization be installing SC4S? [Y/N] ' SC4S_INSTALL
			fi
			case "$SC4S_INSTALL" in
				[Yy]* )
					if [ ! -z "$SC4S_TOKEN" ]; then
						echo "------------------------------------------------------------------"
						echo "Generated SC4S HEC Token: $SC4S_TOKEN"
					else
						SC4S_TOKEN=$(uuidgen)
						echo "------------------------------------------------------------------"
						echo "Generated SC4S HEC Token: $SC4S_TOKEN"
					fi
					;;
				* )
				 	 ;;
			esac
			echo "------------------------------------------------------------------"
			if [ ! -z "$SOAR_INSTALL" ]; then
				read -er -p 'Will your organization be using SOAR and installing the SOAR Reporting app? [Y/N] ' -i "$SOAR_INSTALL" SOAR_INSTALL
			else
				read -p 'Will your organization be using SOAR and installing the SOAR Reporting app? [Y/N] ' SOAR_INSTALL
			fi
			case "$SOAR_INSTALL" in
				[Yy]* )
					if [ ! -z "$SOAR_TOKEN" ]; then
						echo "------------------------------------------------------------------"
						echo "Generated SOAR HEC Token: $SOAR_TOKEN"
					else
						SOAR_TOKEN=$(uuidgen)
						echo "------------------------------------------------------------------"
						echo "Generated SOAR HEC Token: $SOAR_TOKEN"
					fi
					;;
				* )
				  	;;
			esac
			echo "------------------------------------------------------------------"
			if [ ! -z "$INDEX_LIST" ]; then
				read -er -p 'Enter a SPACE-delimited list of additional EVENT indexes your organization wants to define: ' -i "$INDEX_LIST" INDEX_LIST
			else
				read -p 'Enter a SPACE-delimited list of additional EVENT indexes your organization wants to define: ' INDEX_LIST
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$M_INDEX_LIST" ]; then
				read -er -p 'Enter a SPACE-delimited list of additional METRICS indexes your organization wants to define: ' -i "$M_INDEX_LIST" M_INDEX_LIST
			else
				read -p 'Enter a SPACE-delimited list of additional METRICS indexes your organization wants to define: ' M_INDEX_LIST
			fi
			echo "------------------------------------------------------------------"
			if [ ! -z "$IDC" ]; then
				read -er -p "Does/Will your organization's environment utilize indexer clustering? [Y/N] " -i "$IDC" IDC
			else
				read -p "Does/Will your organization's environment utilize indexer clustering? [Y/N] " IDC
			fi
			echo "------------------------------------------------------------------"
			if [ "$IDC" == "y" ]; then
				if [ ! -z "$MULTISITE" ]; then
					read -er -p "Does/Will your organization's environment utilize multisite indexer clustering? [Y/N] " -i "$MULTISITE" MULTISITE
				else
					read -p "Does/Will your organization's environment utilize multisite indexer clustering? [Y/N] " MULTISITE
				fi
			fi
			case "$IDC" in
				[Yy]* )
					echo "------------------------------------------------------------------"
					if [ ! -z "$CM_HOST" ]; then
						read -er -p "Enter the hostname/IP of the cluster manager: " -i "$CM_HOST" CM_HOST
					else
						read -p "Enter the hostname/IP of the cluster manager: " CM_HOST
					fi
					echo "------------------------------------------------------------------"
					if [ ! -z "$CM_P4SK" ]; then
						echo "Current pass4SymmKey for $IDC_LABEL: $CM_P4SK"
						echo "It is recommended to change it manually in \"${ORGANIZATION}_variables.sh\" if needed."
					else
						read -s -p "Enter pass4SymmKey for the cluster members: " CM_P4SK
						printf "\n"
					fi
					echo "------------------------------------------------------------------"
					if [ ! -z "$CM_REP_PORT" ]; then
						read -er -p "Enter the indexer cluster replication port: " -i "$CM_REP_PORT" CM_REP_PORT
					else
						read -p "Enter the indexer cluster replication port: " CM_REP_PORT
					fi
					if [ "$MULTISITE" == "n" ]; then
						echo "------------------------------------------------------------------"
						if [ ! -z "$REP_FACTOR" ]; then
							read -er -p "Enter the replication factor for the indexer cluster: " -i "$REP_FACTOR" REP_FACTOR
						else
							read -p "Enter the replication factor for the indexer cluster: " REP_FACTOR
						fi
						if [ "$S2_INSTALL" == "y" ]; then
							echo "------------------------------------------------------------------"
							echo "Setting the search factor to $REP_FACTOR to support SmartStore configuration..."
							SEARCH_FACTOR=$REP_FACTOR
						else
							echo "------------------------------------------------------------------"
							if [ ! -z "$SEARCH_FACTOR" ]; then
								read -er -p "Enter the search factor for the indexer cluster: " -i "$SEARCH_FACTOR" SEARCH_FACTOR
							else
								read -p "Enter the search factor for the indexer cluster: " SEARCH_FACTOR
							fi
						fi
					else
						echo "------------------------------------------------------------------"
						if [ ! -z "$SITE_REP_FACTOR" ]; then
							echo "Example: origin:1,site1:1,site2:1,total:3"
							read -er -p "Enter the site replication factor for the indexer cluster: " -i "$SITE_REP_FACTOR" SITE_REP_FACTOR
						else
							echo "Example: origin:1,site1:1,site2:1,total:3"
							read -p "Enter the site replication factor for the indexer cluster: " SITE_REP_FACTOR
						fi
						RF_TOTAL=$(echo "$SITE_REP_FACTOR" | sed "s/^.*total://")
						echo "------------------------------------------------------------------"
						echo "Setting global replication factor to \"$RF_TOTAL\"."
						REP_FACTOR="$RF_TOTAL"
						echo "------------------------------------------------------------------"
						if [ ! -z "$SITE_SEARCH_FACTOR" ]; then
							echo "Example: origin:2,total:2"
							read -er -p "Enter the site search factor for the indexer cluster: " -i "$SITE_SEARCH_FACTOR" SITE_SEARCH_FACTOR
						else
							echo "Example: origin:2,total:2"
							read -p "Enter the site search factor for the indexer cluster: " SITE_SEARCH_FACTOR
						fi
						SF_TOTAL=$(echo "$SITE_SEARCH_FACTOR" | sed "s/^.*total://")
						echo "------------------------------------------------------------------"
						echo "Setting global search factor to \"$SF_TOTAL\"."
						SEARCH_FACTOR="$SF_TOTAL"
					fi
					echo "------------------------------------------------------------------"
					if [ ! -z "$IDC_LABEL" ]; then
						read -er -p "Enter the label for the indexer cluster: " -i "$IDC_LABEL" IDC_LABEL
					else
						read -p "Enter the label for the indexer cluster: " IDC_LABEL
					fi
					case $MULTISITE in
					[Yy]* )
						FUTURE_MS="n"
						echo "------------------------------------------------------------------"
						if [ ! -z "$SITE_COUNT" ]; then
							read -er -p "How many sites with your organization be configuring? " -i "$SITE_COUNT" SITE_COUNT
						else
							read -p "How many sites with your organization be configuring? " SITE_COUNT
						fi
						echo "------------------------------------------------------------------"
						if [ ! -z "$SEARCH_AFFINITY" ]; then
							read -er -p "Will your organization enable search affinity during search? [Y/N] " -i "$SEARCH_AFFINITY" SEARCH_AFFINITY
						else
							read -p "Will your organization enable search affinity during search? [Y/N] " SEARCH_AFFINITY
						fi
						;;
					[Nn]* )
						echo "------------------------------------------------------------------"
						if [ ! -z "$FUTURE_MS" ]; then
							read -er -p "Does your organization think they will ever expand to use multisite clutering? [Y/N] " -i "$FUTURE_MS" FUTURE_MS
						else
							read -p "Does your organization think they will ever expand to use multisite clutering? [Y/N] " FUTURE_MS
						fi
						;;
					esac
					echo "------------------------------------------------------------------"
					if [ ! -z "$DISCOVERY" ]; then
						read -er -p "Does/Will your organization's environment utilize indexer discovery? [Y/N] " -i "$DISCOVERY" DISCOVERY
					else
						read -p "Does/Will your organization's environment utilize indexer discovery? [Y/N] " DISCOVERY
					fi
					case $DISCOVERY in
						[Yy]* )
							echo "------------------------------------------------------------------"
							if [ ! -z "$CM_ID_P4SK" ]; then
								echo "Current pass4SymmKey for indexer discovery on $IDC_LABEL: $CM_ID_P4SK"
								echo "It is recommended to change it manually in \"${ORGANIZATION}_variables.sh\" if needed."
							else
								read -s -p "Enter pass4SymmKey for indexer discovery: " CM_ID_P4SK
								printf "\n"
							fi
							echo "------------------------------------------------------------------"
							if [ ! -z "$INDEXER_LIST" ]; then
								read -er -p 'Enter COMMA-delimited list of 2 or 3 indexers with their indexing port: ' -i "$INDEXER_LIST" INDEXER_LIST
							else
								read -p 'Enter COMMA-delimited list of 2 or 3 indexers with their indexing port: ' INDEXER_LIST
							fi
							;;
						[Nn]* )
							echo "------------------------------------------------------------------"
							if [ ! -z "$INDEXER_LIST" ]; then
								read -er -p 'Enter COMMA-delimited list of all indexers with their indexing port: ' -i "$INDEXER_LIST" INDEXER_LIST
							else
								read -p 'Enter COMMA-delimited list of all indexers with their indexing port: ' INDEXER_LIST
							fi
							;;
					esac
					;;
				[Nn]* )
					echo "------------------------------------------------------------------"
					if [ ! -z "$INDEXER_LIST" ]; then
						read -er -p 'Enter COMMA-delimited list of all indexers with their indexing port: ' -i "$INDEXER_LIST" INDEXER_LIST
					else
						read -p 'Enter COMMA-delimited list of all indexers with their indexing port: ' INDEXER_LIST
					fi
				;;
			esac
			echo "------------------------------------------------------------------"
			if [ ! -z "$SHC" ]; then
				read -er -p "Does/Will your organization's environment utilize search head clustering? [Y/N] " -i "$SHC" SHC
			else
				read -p "Does/Will your organization's environment utilize search head clustering? [Y/N] " SHC
			fi
			case "$SHC" in
			[Yy]* )
				echo "------------------------------------------------------------------"
				if [ ! -z "$SHC_DEPLOYER_HOST" ]; then
					read -er -p "Enter the hostname/IP of the deployer: " -i "$SHC_DEPLOYER_HOST" SHC_DEPLOYER_HOST
				else
					read -p "Enter the hostname/IP of the deployer: " SHC_DEPLOYER_HOST
				fi
				echo "------------------------------------------------------------------"
				if [ ! -z "$SHC_P4SK" ]; then
					echo "Current pass4SymmKey for search head cluster $SHC_LABEL: $SHC_P4SK"
					echo "It is recommended to change it manually in \"${ORGANIZATION}_variables.sh\" if needed."
				else
					read -s -p "Enter pass4SymmKey for the cluster members: " SHC_P4SK
					printf "\n"
				fi
				echo "------------------------------------------------------------------"
				if [ ! -z "$SHC_REP_PORT" ]; then
					read -er -p "Enter the search head cluster replication port: " -i "$SHC_REP_PORT" SHC_REP_PORT
				else
					read -p "Enter the search head cluster replication port: " SHC_REP_PORT
				fi
				echo "------------------------------------------------------------------"
				if [ ! -z "$SHC_LABEL" ]; then
					read -er -p "Enter the label for the search head cluster: " -i "$SHC_LABEL" SHC_LABEL
				else
					read -p "Enter the label for the search head cluster: " SHC_LABEL
				fi
				echo "------------------------------------------------------------------"
				if [ ! -z "$SHC_MEMBERS" ]; then
					read -er -p "Enter a SPACE-delimited list of the hostnames or IPs of the SHC members: " -i "$SHC_MEMBERS" SHC_MEMBERS
				else
					read -p "Enter a SPACE-delimited list of the hostnames or IPs of the SHC members: " SHC_MEMBERS
				fi
				echo "------------------------------------------------------------------"
				if [ ! -z "$VC_BASE_URL" ]; then
				   read -er -p "Enter base URL (without a protocol) for the target version control: " -i "$VC_BASE_URL" VC_BASE_URL
				else
				    read -p "Enter base URL (without a protocol) for the target version control: " VC_BASE_URL
				fi
				echo "------------------------------------------------------------------"
				if [ ! -z "$VC_USER" ]; then
				   read -er -p "Enter the username used to access version control: " -i "$VC_USER" VC_USER
				else
				    read -p "Enter the username used to access version control: " VC_USER
				fi
				echo "------------------------------------------------------------------"
				if [ ! -z "$VC_PASSWORD" ]; then
					echo "Current version control password for user $VC_USER: $VC_PASSWORD"
					echo "It is recommended to change it manually in \"${ORGANIZATION}_variables.sh\" if needed."
				else
					read -s -p "Enter password for the version control user: " $VC_PASSWORD
					printf "\n"
				fi
				;;
			[Nn]* )
				echo > /dev/null 2>&1
				;;
			esac
			echo "------------------------------------------------------------------"
			echo "#!/bin/bash
##########################################################################
######################### ORGANIZATION VARIABLE ##########################
##########################################################################
## Set this to the abbrevation of the organization's name.
ORGANIZATION=\"${ORGANIZATION}\"

##########################################################################
######################## SPLUNK RUNTIME VARIABLES ########################
##########################################################################
## Configure the Splunk admin account name.
SPLUNKADMIN=\"$SPLUNKADMIN\"
## Configure the password for the Splunk admin account.
ADMINPASS='$ADMINPASS'
## Configure the management port value used in this deployment.
MGMT_PORT=\"$MGMT_PORT\"
## Configure the location of the Splunk installation.
SPLUNK_HOME=\"$SPLUNK_HOME\"
## Configure the version of the Splunk installation.
SPLUNK_VERSION=\"$SPLUNK_VERSION\"

##########################################################################
###################### SPLUNK ARCHITECTURE VARIABLES #####################
##########################################################################
## Configure the hostname/IP of the deployment server.
DS_HOST=\"$DS_HOST\"
## Configure the hostname/IP of the license manager.
LM_HOST=\"$LM_HOST\"
## Comma delimmited list of indexers where data is to be sent. Ex. idx1.splunk.com:9997, idx2.splunk.com:9997
INDEXER_LIST=\"$INDEXER_LIST\"

##########################################################################
####################### INDEXER CLUSTERING CONFIGS #######################
##########################################################################
## Configure whether indexer clustering will be used at your organization. The options are 'y'/'n'.
IDC=\"$IDC\"
## Configure the number of indexers that will be deployed within the environment.
INDEXER_COUNT=\"$INDEXER_COUNT\"
## Configure the cluster manager hostname/IP.
CM_HOST=\"$CM_HOST\"
## Configure if the organization will be using indexer discovery. The options are 'y'/'n'.
DISCOVERY=\"$DISCOVERY\"
## Configure the pass4SymmKey for the cluster members.
CM_P4SK='$CM_P4SK'
## Configure the pass4SymmKey for indexer discovery.
CM_ID_P4SK='$CM_ID_P4SK'
## Configure the cluster replication port.
CM_REP_PORT=\"$CM_REP_PORT\"
## Configure the replication factor for the indexer cluster.
REP_FACTOR=\"$REP_FACTOR\"
## Configure the search factor for the indexer cluster.
SEARCH_FACTOR=\"$SEARCH_FACTOR\"
## Configure a indexer cluster label.
IDC_LABEL=\"$IDC_LABEL\"

##########################################################################
########################### MULTISITE CONFIGS ############################
##########################################################################
## Configure if your organization will utilize multisite indexer clustering. The options are 'y'/'n'.
MULTISITE=\"$MULTISITE\"
## Configure the number of sites your organization will have.
SITE_COUNT=\"$SITE_COUNT\"
## Configure the site replication factor.
SITE_REP_FACTOR=\"$SITE_REP_FACTOR\"
## Configure the site search factor.
SITE_SEARCH_FACTOR=\"$SITE_SEARCH_FACTOR\"
## Configure whether search heads will use search affinity. The options are 'y'/'n'.
SEARCH_AFFINITY=\"$SEARCH_AFFINITY\"
## Configure whether multisite clustering is possible in the future. The options are 'y'/'n'.
FUTURE_MS=\"$FUTURE_MS\"

##########################################################################
############################ INDEXING CONFIGS ############################
##########################################################################
## Configure the port that will be used for indexing.
INDEXING_PORT=\"$INDEXING_PORT\"
## Configure the volume path where hot/warm indexed data will be stored.
HOTWARM_VOLUME='$HOTWARM_VOLUME'
## Configure the maxmium size of the hot/warm volume.
HOTWARM_MAX=\"$HOTWARM_MAX\"
## Configure the volume path for cold storage on indexers.
COLD_VOLUME='$COLD_VOLUME'
## Configure the maxmium size of the cold volume.
COLD_MAX=\"$COLD_MAX\"
## Configure the default retention in seconds.
RETENTION=\"$RETENTION\"
## Configure the default maximum index size (MB) on indexers.
INDEX_MAX=\"$INDEX_MAX\"
## Configure if your organization will be accelerating data models. The options are 'y'/'n'.
SPLUNK_SUMMARIES=\"$SPLUNK_SUMMARIES\"
## Configure if your organization will be installing ES to create the ES indexes. The options are 'y'/'n'.
ES_INSTALL=\"$ES_INSTALL\"
## Configure if your organization will be installing ITSI to create the ITSI indexes. The options are 'y'/'n'.
ITSI_INSTALL=\"$ITSI_INSTALL\"
## Configure if your organization will be installing SAI to create the SAI indexes. The options are 'y'/'n'.
SAI_INSTALL=\"$SAI_INSTALL\"
## Configure a HEC token for SAI collectd collection.
SAI_TOKEN=\"$SAI_TOKEN\"
## Configure if your organization will be installing SC4S to create the SC4S indexes. The options are 'y'/'n'.
SC4S_INSTALL=\"$SC4S_INSTALL\"
## Configure a HEC token for SC4S.
SC4S_TOKEN=\"$SC4S_TOKEN\"
## Configure if your organization will be installing SOAR to create the indexes for receiving SOAR events. The options are 'y'/'n'.
SOAR_INSTALL=\"$SOAR_INSTALL\"
## Configure a HEC token for SOAR.
SOAR_TOKEN=\"$SOAR_TOKEN\"
## Configure a SPACE-delimited list of additional event indexes that will be configured.
INDEX_LIST=\"$INDEX_LIST\"
## Configure a SPACE-delimited list of additional metrics indexes that will be configured.
M_INDEX_LIST=\"$M_INDEX_LIST\"

##########################################################################
########################### SMARTSTORE CONFIGS ###########################
##########################################################################
## Configure if your organization will be utilizing SmartStore. The options are 'y'/'n'.
S2_INSTALL=\"$S2_INSTALL\"
## Configure the maximum size of the local cache on the indexers in MB.
S2_CACHE_MAX=\"$S2_CACHE_MAX\"
## Configure the path to the S3 bucket for SmartStore. Ex. s3://bucket-name
S3_PATH=\"$S3_PATH\"
## Configure the S3 endpoint for SmartStore. Ex. https://s3.us-east-1.amazonaws.com
S3_ENDPOINT=\"$S3_ENDPOINT\"
## Configure the AWS access key for the IAM account.
S3_ACCESS_KEY=\"$S3_ACCESS_KEY\"
## Configure the AWS secret key for the IAM account.
S3_SECRET_KEY=\"$S3_SECRET_KEY\"

##########################################################################
##################### SEARCH HEAD CLUSTERING CONFIGS #####################
##########################################################################
## Configure whether search head clustering will be used at your organization. The options are 'y'/'n'.
SHC=\"$SHC\"
## Configure the deployer hostname/IP.
SHC_DEPLOYER_HOST=\"$SHC_DEPLOYER_HOST\"
## Configure the Pass4SymmKey for the members.
SHC_P4SK='$SHC_P4SK'
## Configure the search head cluster replication port.
SHC_REP_PORT=\"$SHC_REP_PORT\"
## Configure a search head cluster label.
SHC_LABEL=\"$SHC_LABEL\"
## Configure a SPACE-delimited list of the SHC member hostnames.
SHC_MEMBERS=\"$SHC_MEMBERS\"

##########################################################################
###################### VERSION CONTROL CREDENTIALS #######################
##########################################################################
## Configure base URL (without a protocol) for the target version control
VC_BASE_URL=\"$VC_BASE_URL\"
## Configure the username used to authenticate into version control
VC_USER=\"$VC_USER\"
## Configure the password used to authenticate into version control
VC_PASSWORD='$VC_PASSWORD'
"  > "${PWD}/${ORGANIZATION}_variables.sh"
			chmod +x "${PWD}/${ORGANIZATION}_variables.sh"
			;;
		[Nn]* )
			echo > /dev/null 2>&1
			;;
		[*] )
			echo "Please answer yes or no..."
	esac
}

deploymentclient() {
	if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_deploymentclient" ]; then
		mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_deploymentclient/local"
		mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_deploymentclient/metadata"
	fi
		echo "[deployment-client]
# Set the phoneHome at the end of the PS engagement
# 10 minutes
# phoneHomeIntervalInSecs = 600

[target-broker:deploymentServer]
targetUri = $DS_HOST:$MGMT_PORT
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_deploymentclient/local/deploymentclient.conf"
}

license_manager() {
	if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_full_license_server" ]; then
		mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_full_license_server/local"
		mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_full_license_server/metadata"
	fi
	echo "# In distributed environments, it's common to have a lone search head acting
# as the license manager as well. In this configuration, providing the URI
# of the license manager is easiest within the indexer_base configuration.
# In the event that there are multiple search heads, you could instead use
# the org_all_license app, shipped to the non-license SH, as well as all of
# the indexers. In either event, the settings are the same.

[license]
master_uri = https://$LM_HOST:$MGMT_PORT
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_full_license_server/local/server.conf"
}

outputs() {
	if [  "$IDC" = "y" ]; then
		if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_forwarder_outputs" ]; then
			mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_forwarder_outputs/local"
			mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_forwarder_outputs/metadata"
		fi
		echo "# BASE SETTINGS
[tcpout]
defaultGroup = primary_indexers
maxQueueSize = 7MB
useACK = true
forceTimebasedAutoLB = true

[tcpout:primary_indexers]
server = $INDEXER_LIST
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_forwarder_outputs/local/outputs.conf"
		if [ "$DISCOVERY" = "y" ]; then
	echo "indexerDiscovery = clustered_indexers

[indexer_discovery:clustered_indexers]
pass4SymmKey =
master_uri = https://$CM_HOST:$MGMT_PORT

# SSL SETTINGS
# Used only if you're using SSL for the indexing port
# sslCertPath = \$SPLUNK_HOME/etc/auth/server.pem
# sslRootCAPath = \$SPLUNK_HOME/etc/auth/ca.pem
# sslPassword = password
# sslVerifyServerCert = true

# COMMON NAME CHECKING - NEED ONE STANZA PER INDEXER
# The same certificate can be used across all of them, but the configuration
# here requires these settings to be per-indexer, so the same block of
# configuration would have to be repeated for each.

# [tcpout-server://10.1.12.112:9997]
# sslCertPath = \$SPLUNK_HOME/etc/certs/myServerCertificate.pem
# sslRootCAPath = \$SPLUNK_HOME/etc/certs/myCAPublicCertificate.pem
# sslPassword = server_privkey_password
# sslVerifyServerCert = true
# sslCommonNameToCheck = servername
# altCommonNameToCheck = servername" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_forwarder_outputs/local/outputs.conf"
		echo "# By default a universal or light forwarder is limited to 256kB/s
# Either set a different limit in kB/s, or set the value to zero to
# have no limit.
# Note that a full speed UF can overwhelm a single indexer.

# [thruput]
# maxKBps = 0
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_forwarder_outputs/local/limits.conf"
	else
		echo "# indexerDiscovery = clustered_indexers

# [indexer_discovery:clustered_indexers]
# pass4SymmKey = <MUST_MATCH_MASTER>

# SSL SETTINGS
# Used only if you're using SSL for the indexing port
# sslCertPath = \$SPLUNK_HOME/etc/auth/server.pem
# sslRootCAPath = \$SPLUNK_HOME/etc/auth/ca.pem
# sslPassword = password
# sslVerifyServerCert = true

# COMMON NAME CHECKING - NEED ONE STANZA PER INDEXER
# The same certificate can be used across all of them, but the configuration
# here requires these settings to be per-indexer, so the same block of
# configuration would have to be repeated for each.

# [tcpout-server://10.1.12.112:9997]
# sslCertPath = \$SPLUNK_HOME/etc/certs/myServerCertificate.pem
# sslRootCAPath = \$SPLUNK_HOME/etc/certs/myCAPublicCertificate.pem
# sslPassword = server_privkey_password
# sslVerifyServerCert = true
# sslCommonNameToCheck = servername
# altCommonNameToCheck = servername" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_forwarder_outputs/local/outputs.conf"
		echo "# By default a universal or light forwarder is limited to 256kB/s
# Either set a different limit in kB/s, or set the value to zero to
# have no limit.
# Note that a full speed UF can overwhelm a single indexer.

# [thruput]
# maxKBps = 0
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_forwarder_outputs/local/limits.conf"
		fi
	else
		if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_forwarder_outputs" ]; then
			mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_forwarder_outputs/local"
			mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_forwarder_outputs/metadata"
		fi
		echo "# BASE SETTINGS
[tcpout]
defaultGroup = primary_indexers
maxQueueSize = 7MB
useACK = true
forceTimebasedAutoLB = true

[tcpout:primary_indexers]
server = $INDEXER_LIST
# indexerDiscovery = clustered_indexers

# [indexer_discovery:clustered_indexers]
# pass4SymmKey = <MUST_MATCH_MASTER>
# This must include protocol and port like the example below.
# master_uri = https://master.example.com:8089

# SSL SETTINGS
# sslCertPath = \$SPLUNK_HOME/etc/auth/server.pem
# sslRootCAPath = \$SPLUNK_HOME/etc/auth/ca.pem
# sslPassword = password
# sslVerifyServerCert = true

# COMMON NAME CHECKING - NEED ONE STANZA PER INDEXER
# The same certificate can be used across all of them, but the configuration
# here requires these settings to be per-indexer, so the same block of
# configuration would have to be repeated for each.

# [tcpout-server://10.1.12.112:9997]
# sslCertPath = \$SPLUNK_HOME/etc/certs/myServerCertificate.pem
# sslRootCAPath = \$SPLUNK_HOME/etc/certs/myCAPublicCertificate.pem
# sslPassword = server_privkey_password
# sslVerifyServerCert = true
# sslCommonNameToCheck = servername
# altCommonNameToCheck = servername
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_forwarder_outputs/local/outputs.conf"
		echo "# By default a universal or light forwarder is limited to 256kB/s
# Either set a different limit in kB/s, or set the value to zero to
# have no limit.
# Note that a full speed UF can overwhelm a single indexer.

# [thruput]
# maxKBps = 0
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_forwarder_outputs/local/limits.conf"
	fi
}

ms_site_definitions() {
	if [ "$MULTISITE" == "y" ]; then
		for i in $(eval echo "{1..$SITE_COUNT..1}"); do
			if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_indexer_site$i" ]; then
				mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_indexer_site$i/local"
				mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_indexer_site$i/metadata"
			fi
			echo "[general]
site = site$i
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_indexer_site$i/local/server.conf"
			BUILD=site$i
			if [ ! -z "$AVAILABLE_SITES" ]; then
				AVAILABLE_SITES="${AVAILABLE_SITES},${BUILD}"
			else
				AVAILABLE_SITES="${BUILD}"
			fi
		done
	else
		AVAILABLE_SITES="site1"
	fi
}

cm_base() {
	if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_manager_base" ]; then
		mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_manager_base/local"
		mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_manager_base/metadata"
	fi
	echo "[clustering]
mode = manager
pass4SymmKey =
cluster_label = $IDC_LABEL
replication_factor = $REP_FACTOR
search_factor = $SEARCH_FACTOR" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_manager_base/local/server.conf"
	if [ "$INDEXER_COUNT" -gt 20 ]; then
		echo "rep_cxn_timeout = 120
rep_max_rcv_timeout = 600
rep_max_send_timeout = 600
rep_rcv_timeout = 120
rep_send_timeout = 120
send_timeout = 600
heartbeat_period = 10" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_manager_base/local/server.conf"
	fi
	if [ "$MULTISITE" == "y" ]; then
			echo "
## Multisite Settings
multisite = true
available_sites = $AVAILABLE_SITES
site_replication_factor = $SITE_REP_FACTOR
site_search_factor = $SITE_SEARCH_FACTOR
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_manager_base/local/server.conf"
	elif [ "$FUTURE_MS" == "y" ]; then
		echo "
## Setting multisite out of the gate replication will allow for easier expansion later without
## needing to regenerate the bucket IDs later using the \"constrain_singlesite_buckets = false\" setting.
## It's meant to save processing time when migrating from single site to true multisite in the future.

multisite = true
available_sites = site1
site_replication_factor = origin:$REP_FACTOR,total:$REP_FACTOR
site_search_factor = origin:$SEARCH_FACTOR,total:$SEARCH_FACTOR
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_manager_base/local/server.conf"
	else
		echo "multisite = false
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_manager_base/local/server.conf"
	fi
	if [ "$MULTISITE" == "y" ] || [ "$FUTURE_MS" == "y" ]; then
		echo "[general]
site = site0" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_manager_base/local/server.conf"
	fi
	if [ ! -z "$CM_ID_P4SK" ]; then
			echo "
[indexer_discovery]
pass4SymmKey =
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_manager_base/local/server.conf"
	fi
	if [ "$MGMT_PORT" != "8089" ]; then
		echo "[settings]
mgmtHostPort = 0.0.0.0:$MGMT_PORT
enableSplunkWebSSL = true
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_manager_base/local/web.conf"
	fi
}

sh_cm_member() {
	if [ "$IDC" = "y" ]; then
		if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base" ]; then
			mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/local"
			mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/metadata"
		fi
		echo "[clustering]
mode = searchhead
manager_uri = https://$CM_HOST:$MGMT_PORT
pass4SymmKey =
cluster_label = $IDC_LABEL" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/local/server.conf"
		if [ "$FUTURE_MS" == "y" ] || [ "$MULTISITE" == "y" ]; then
			echo "multisite = true" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/local/server.conf"
		fi
		if [ "$SEARCH_AFFINITY" == "n" ] || [ "$FUTURE_MS" == "y" ]; then
			echo "
[general]
site = site0
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/local/server.conf"
		fi
		if [ "$INDEXER_COUNT" -gt 20 ]; then
			echo "[sslConfig]
useClientSSLCompression=false" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/local/server.conf"
			echo "[distributedSearch]
statusTimeout = 120
connectionTimeout = 120
authTokenConnectionTimeout = 120
authTokenSendTimeout = 120
authTokenReceiveTimeout = 120

[replicationSettings]
connectionTimeout = 120
sendRcvTimeout = 120
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/local/distsearch.conf"
		fi
		if [ "$MGMT_PORT" != "8089" ] && [ "$ES_INSTALL" == "y" ]; then
			echo "[settings]
mgmtHostPort = 0.0.0.0:$MGMT_PORT
max_upload_size = 1024
enableSplunkWebSSL = true
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/local/web.conf"
		elif [ "$MGMT_PORT" != "8089" ]; then
			echo "[settings]
mgmtHostPort = 0.0.0.0:$MGMT_PORT
enableSplunkWebSSL = true
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/local/web.conf"
		elif [ "$ES_INSTALL" == "y" ]; then
			echo "[settings]
max_upload_size = 1024
enableSplunkWebSSL = true
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/local/web.conf"
		else
			echo "[settings]
enableSplunkWebSSL = true" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/local/web.conf"
		fi
	fi
}

indexer_cm_member() {
	if [ "$IDC" = "y" ]; then
		if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_indexer_base" ]; then
			mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_indexer_base/local"
			mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_indexer_base/metadata"
		fi
		echo "[clustering]
mode = peer
manager_uri = https://$CM_HOST:$MGMT_PORT
pass4SymmKey =
cluster_label = $IDC_LABEL" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_indexer_base/local/server.conf"
		if [ "$INDEXER_COUNT" -gt 20 ]; then
			echo "cxn_timeout = 600
rep_cxn_timeout = 120
rep_send_timeout = 120
rep_rcv_timeout = 120
rep_max_rcv_timeout = 600
rep_max_send_timeout = 600
heartbeat_timeout = 120

[httpServer]
busyKeepAliveIdleTimeout = 180
streamInWriteTimeout = 30

[sslConfig]
useClientSSLCompression=false" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_indexer_base/local/server.conf"
		fi
		if [ "$FUTURE_MS" == "y" ] || [ "$MULTISITE" == "y" ]; then
		echo "multisite = true

[replication_port://$CM_REP_PORT]" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_indexer_base/local/server.conf"
		elif [ "$FUTURE_MS" == "y" ] && [ "$MULTISITE" == "n" ]; then
			echo "multisite = true

[general]
site = site1

[replication_port://$CM_REP_PORT]" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_indexer_base/local/server.conf"
		else
			echo "
[replication_port://$CM_REP_PORT]" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_indexer_base/local/server.conf"
		fi
	fi
}

indexer_base() {
	if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_base" ]; then
		mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_base/local"
		mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_base/metadata"
	fi
	echo "# In larger environments, where there are more than, say, three indexers,
# it's common to disable the Splunk UI. This helps avoid configuration issues
# caused by logging in to the UI to do something directly via the manager,
# as well as saving some system resources.

[settings]
startwebserver = 0" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_base/local/web.conf"
	if [ "$MGMT_PORT" != "8089" ]; then
		echo "mgmtHostPort = 0.0.0.0:$MGMT_PORT
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_base/local/web.conf"
	fi
	echo "# BASE SETTINGS
[splunktcp://$INDEXING_PORT]

## Template for using SSL for indexing port
# [splunktcp-ssl://9996]

# SSL SETTINGS
# [SSL]
# rootCA = $SPLUNK_HOME/etc/auth/cacert.pem
# serverCert = $SPLUNK_HOME/etc/auth/server.pem
# password = password
# requireClientCert = false
# If using compressed = true, it must be set on the forwarder outputs as well.
# compressed = true
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_base/local/inputs.conf"
	echo "[kvstore]
disabled = 1
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_base/local/server.conf"
}

indexer_volumes() {
	if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_volume_indexes" ]; then
		mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_volume_indexes/local"
		mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_volume_indexes/metadata"
	fi
	echo "[volume:primary]
path = $HOTWARM_VOLUME
maxVolumeDataSizeMB = $HOTWARM_MAX

[volume:cold]
path = $COLD_VOLUME
maxVolumeDataSizeMB = $COLD_MAX
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_volume_indexes/local/indexes.conf"
	case "$SPLUNK_SUMMARIES" in
		[Yy]* )
			echo "[volume:_splunk_summaries]
path = $HOTWARM_VOLUME
maxVolumeDataSizeMB = 100000
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_volume_indexes/local/indexes.conf"
			;;
		[Nn]* )
			echo > /dev/null 2>&1
	esac
}

indexer_s2_volumes() {
	if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_s3volume_indexes" ]; then
		mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_s3volume_indexes/local"
		mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_s3volume_indexes/metadata"
	fi
	if [ ! -z $S3_ACCESS_KEY ]; then
		echo "[default]
remotePath = volume:s3_volume/\$_index_name

[volume:s3_volume]
storageType = remote
path = $S3_PATH
remote.s3.endpoint = $S3_ENDPOINT
remote.s3.access_key = $S3_ACCESS_KEY
remote.s3.secret_key = $S3_SECRET_KEY

[main]
remotePath   = volume:s3_volume/defaultdb

[history]
remotePath   = volume:s3_volume/historydb

[summary]
remotePath   = volume:s3_volume/summarydb

[_internal]
remotePath   = volume:s3_volume/_internaldb

[_audit]
remotePath   = volume:s3_volume/audit

[_thefishbucket]
remotePath   = volume:s3_volume/fishbucket
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_s3volume_indexes/local/indexes.conf"
	else
		echo "[default]
remotePath = volume:s3_volume/\$_index_name

[volume:s3_volume]
storageType = remote
path = $S3_PATH
remote.s3.endpoint = $S3_ENDPOINT

[main]
remotePath   = volume:s3_volume/defaultdb

[history]
remotePath   = volume:s3_volume/historydb

[summary]
remotePath   = volume:s3_volume/summarydb

[_internal]
remotePath   = volume:s3_volume/_internaldb

[_audit]
remotePath   = volume:s3_volume/audit

[_thefishbucket]
remotePath   = volume:s3_volume/fishbucket
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_s3volume_indexes/local/indexes.conf"
	fi
	case "$ES_INSTALL" in
		[Yy]* )
			echo "# ENTERPRISE SECURITY INDEXES
###### DA-ESS-AccessProtection ######
[gia_summary]
remotePath   = volume:s3_volume/gia_summarydb

###### DA-ESS-ThreatIntelligence ######
[ioc]
remotePath   = volume:s3_volume/iocdb

[threat_activity]
remotePath   = volume:s3_volume/threat_activitydb

###### SA-AuditAndDataProtection ######
[audit_summary]
remotePath   = volume:s3_volume/audit_summarydb

###### SA-EndpointProtection ######
[endpoint_summary]
remotePath   = volume:s3_volume/endpoint_summarydb

###### SA-NetworkProtection ######
[whois]
remotePath   = volume:s3_volume/whoisdb

###### SA-ThreatIntelligence ######
[notable]
remotePath   = volume:s3_volume/notabledb

[notable_summary]
remotePath   = volume:s3_volume/notable_summarydb

[risk]
remotePath   = volume:s3_volume/riskdb

###### Splunk_SA_CIM ######
[cim_modactions]
remotePath   = volume:s3_volume/cim_modactionsdb

[cim_summary]
remotePath   = volume:s3_volume/cim_summarydb
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_s3volume_indexes/local/indexes.conf"
			;;
		* )
	esac
	echo "[cachemanager]
max_concurrent_uploads = 8
max_cache_size = $S2_CACHE_MAX
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_s3volume_indexes/local/server.conf"
}

all_indexes() {
	if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes" ]; then
		mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local"
		mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/metadata"
	fi
	echo "# Parameters commonly leveraged here:
# maxTotalDataSizeMB - sets the maximum size of the index data, in MBytes,
#   over all stages (hot, warm, cold). This is the *indexed* volume (actual
#   disk space used) not the license volume. This is separate from volume-
#   based retention and the lower of this and volumes will take effect.
#   NOTE: THIS DEFAULTS TO 500GB - BE SURE TO RAISE FOR LARGE ENVIRONMENTS!
#
# maxDataSize - this constrains how large a *hot* bucket can grow; it is an
#   upper bound. Buckets may be smaller than this (and indeed, larger, if
#   the data source grows very rapidly--Splunk checks for the need to rotate
#   every 60 seconds).
#   \"auto\" means 750MB
#   \"auto_high_volume\" means 10GB on 64-bit systems, and 1GB on 32-bit.
#   Otherwise, the number is given in MB
#   (Default: auto)
#
# maxHotBuckets - this defines the maximum number of simultaneously open hot
#   buckets (actively being written to). For indexes that receive a lot of
#   data, this should be 10, other indexes can safely keep the default
#   value. (Default: 3)
#
# homePath - sets the directory containing hot and warm buckets. If it
#   begins with a string like \"volume:<name>\", then volume-based retention is
#   used. [required for new index]
#
# coldPath - sets the directory containing cold buckets. Like homePath, if
#   it begins with a string like \"volume:<name>\", then volume-based retention
#   will be used. The homePath and coldPath can use the same volume, but
#   but should have separate subpaths beneath it. [required for new index]
#
# thawedPath - sets the directory for data recovered from archived buckets
#   (if saved, see coldToFrozenDir and coldToFrozenScript in the docs). It
#   *cannot* reference a volume: specification. This parameter is required,
#   even if thawed data is never used. [required for new index]
#
# frozenTimePeriodInSecs - sets the maximum age, in seconds, of data. Once
#   *all* of the events in an index bucket are older than this age, the
#   bucket will be frozen (default action: delete). The important thing
#   here is that the age of a bucket is defined by the *newest* event in
#   the bucket, and the *event time*, not the time at which the event
#   was indexed.
#
# TSIDX MINIFICATION (version 6.4 or higher)
#   Reduce the size of the tsidx files (the \"index\") within each bucket to
#   a tiny one for space savings. This has a *notable* impact on search,
#   particularly those which are looking for rare or sparse terms, so it
#   should not be undertaken lightly. First enable the feature with the
#   first option shown below, then set the age at which buckets become
#   eligible.
#
# enableTsidxReduction = true / (false) - Enable the function to reduce the
#   size of tsidx files within an index. Buckets older than the time period
#   shown below.
#
# timePeriodInSecBeforeTsidxReduction - sets the minimum age for buckets
#   before they are eligible for their tsidx files to be minified. The
#   default value is 7 days (604800 seconds).
#
# Seconds Conversion Cheat Sheet
#    86400 = 1 day
#   604800 = 1 week
#  2592000 = 1 month
# 31536000 = 1 year
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
	if [ "$S2_INSTALL" == "y" ]; then
		echo "[default]
homePath   = volume:primary/\$_index_name/db
coldPath   = volume:cold/\$_index_name/colddb
thawedPath = \$SPLUNK_DB/\$_index_name/thaweddb
repFactor = auto
frozenTimePeriodInSecs = $RETENTION
journalCompression = zstd
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
		if [ "$SPLUNK_VERSION" -lt "820" ]; then
			echo "tsidxWritingLevel = 3
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
		else
			echo "tsidxWritingLevel = 4
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
		fi
	else
		echo "
[default]
homePath   = volume:primary/\$_index_name/db
coldPath   = volume:cold/\$_index_name/colddb
thawedPath = \$SPLUNK_DB/\$_index_name/thaweddb
repFactor = auto
maxTotalDataSizeMB = $INDEX_MAX
frozenTimePeriodInSecs = $RETENTION
journalCompression = zstd
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
		if [ "$SPLUNK_VERSION" -lt "820" ]; then
			echo "tsidxWritingLevel = 3
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
		else
			echo "tsidxWritingLevel = 4
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
		fi
	fi
	echo "[main]
homePath   = volume:primary/defaultdb/db
coldPath   = volume:cold/defaultdb/colddb
thawedPath = \$SPLUNK_DB/defaultdb/thaweddb

[history]
homePath   = volume:primary/historydb/db
coldPath   = volume:cold/historydb/colddb
thawedPath = \$SPLUNK_DB/historydb/thaweddb

[summary]
homePath   = volume:primary/summarydb/db
coldPath   = volume:cold/summarydb/colddb
thawedPath = \$SPLUNK_DB/summarydb/thaweddb

[_internal]
homePath   = volume:primary/_internaldb/db
coldPath   = volume:cold/_internaldb/colddb
thawedPath = \$SPLUNK_DB/_internaldb/thaweddb

# For version 6.1 and higher
[_introspection]
homePath   = volume:primary/_introspection/db
coldPath   = volume:cold/_introspection/colddb
thawedPath = \$SPLUNK_DB/_introspection/thaweddb

# For version 6.5 and higher
[_telemetry]
homePath   = volume:primary/_telemetry/db
coldPath   = volume:cold/_telemetry/colddb
thawedPath = \$SPLUNK_DB/_telemetry/thaweddb

[_audit]
homePath   = volume:primary/audit/db
coldPath   = volume:cold/audit/colddb
thawedPath = \$SPLUNK_DB/audit/thaweddb

[_thefishbucket]
homePath   = volume:primary/fishbucket/db
coldPath   = volume:cold/fishbucket/colddb
thawedPath = \$SPLUNK_DB/fishbucket/thaweddb
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
	if [ "$SPLUNK_VERSION" -ge "805" ]; then
		echo "## For version 8.0 and higher
[_metrics]
datatype = metric

[_metrics_rollup]
datatype = metric
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
	else
		echo "## For version 8.0 and higher
[_metrics]
datatype = metric
homePath   = volume:primary/_metrics/db
coldPath   = volume:cold/_metrics/colddb
thawedPath = \$SPLUNK_DB/_metrics/thaweddb
repFactor  = auto

[_metrics_rollup]
datatype = metric
homePath   = volume:primary/_metrics_rollup/db
coldPath   = volume:cold/_metrics_rollup/colddb
thawedPath = \$SPLUNK_DB/_metrics_rollup/thaweddb
repFactor  = auto
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
	fi
	if [ "$SPLUNK_VERSION" -ge "920" ]; then
		echo "## For version 9.2 and higher
[_dsphonehome]

[_dsclient]

[_dsappevent]
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
	fi
	case "$ES_INSTALL" in
		[Yy]* )
			echo "## ENTERPRISE SECURITY INDEXES
###### DA-ESS-AccessProtection ######
[gia_summary]
coldPath = volume:cold/gia_summarydb/colddb
homePath = volume:primary/gia_summarydb/db
thawedPath = \$SPLUNK_DB/gia_summarydb/thaweddb

###### DA-ESS-ThreatIntelligence ######
[ioc]
coldPath = volume:cold/iocdb/colddb
homePath = volume:primary/iocdb/db
thawedPath = \$SPLUNK_DB/iocdb/thaweddb

[threat_activity]
coldPath = volume:cold/threat_activitydb/colddb
homePath = volume:primary/threat_activitydb/db
thawedPath = \$SPLUNK_DB/threat_activitydb/thaweddb

###### SA-AuditAndDataProtection ######
[audit_summary]
homePath   = volume:primary/audit_summarydb/db
coldPath   = volume:cold/audit_summarydb/colddb
thawedPath = \$SPLUNK_DB/audit_summarydb/thaweddb

###### SA-EndpointProtection ######
[endpoint_summary]
coldPath = volume:cold/endpoint_summarydb/colddb
homePath = volume:primary/endpoint_summarydb/db
thawedPath = \$SPLUNK_DB/endpoint_summarydb/thaweddb

###### SA-NetworkProtection ######
[whois]
coldPath = volume:cold/whoisdb/colddb
homePath = volume:primary/whoisdb/db
thawedPath = \$SPLUNK_DB/whoisdb/thaweddb

###### SA-ThreatIntelligence ######
[notable]
coldPath = volume:cold/notabledb/colddb
homePath = volume:primary/notabledb/db
thawedPath = \$SPLUNK_DB/notabledb/thaweddb

[notable_summary]
coldPath = volume:cold/notable_summarydb/colddb
homePath = volume:primary/notable_summarydb/db
thawedPath = \$SPLUNK_DB/notable_summarydb/thaweddb

[risk]
coldPath = volume:cold/riskdb/colddb
homePath = volume:primary/riskdb/db
thawedPath = \$SPLUNK_DB/riskdb/thaweddb

###### Splunk_SA_CIM ######
[cim_modactions]
coldPath = volume:cold/cim_modactionsdb/colddb
homePath = volume:primary/cim_modactionsdb/db
thawedPath = \$SPLUNK_DB/cim_modactionsdb/thaweddb

[cim_summary]
coldPath = volume:cold/cim_summarydb/colddb
homePath = volume:primary/cim_summarydb/db
thawedPath = \$SPLUNK_DB/cim_summarydb/thaweddb

###### Splunk_SA_ExtremeSearch ######
[xtreme_contexts]
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
			;;
		* )
	esac
	case "$ITSI_INSTALL" in
		[Yy]* )
			echo "## KPI Summary
[itsi_summary]

## KPI Metrics Summary
[itsi_summary_metrics]
datatype = metric

## Anomaly detection
[anomaly_detection]

[itsi_tracked_alerts]

[itsi_notable_audit]

[itsi_notable_archive]

[itsi_grouped_alerts]

[snmptrapd]

[itsi_import_objects]

[itsi_im_meta]
datatype = event

[itsi_im_metrics]
datatype = metric

## SAI legacy indexes
[em_meta]

[em_metrics]
datatype = metric

[infra_alerts]
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
			;;
		* )
	esac
	case "$SC4S_INSTALL" in
		[Yy]* )
			echo "## SC4S INDEXES
[email]

[epav]

[epintel]

[infraops]

[netauth]

[netdlp]

[netdns]

[netfw]

[netids]

[netlb]

[netops]

[netwaf]

[netproxy]

[netipam]

[oswin]

[oswinsec]

[osnix]

[print]
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
			;;
		* )
	esac
	case "$SOAR_INSTALL" in
		[Yy]* )
			echo "## SOAR INDEXES
[phantom_container]

[phantom_artifact]

[phantom_action_run]

[phantom_app_run]

[phantom_playbook]

[phantom_decided_list]

[phantom_container_comment]

[phantom_container_attachment]

[phantom_asset]

[phantom_app]

[phantom_container_note]

[phantom_workflow_note]

[phantom_note]

[phantom_modalert]
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
			;;
		* )
	esac
	if [ ! -z "$INDEX_LIST" ]; then
		echo "## CUSTOM INDEXES" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
		indexList=($INDEX_LIST)
			for i in "${indexList[@]}" ; do
				echo "[$i]
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
			done
	fi
	if [ ! -z "$M_INDEX_LIST" ]; then
		echo "## CUSTOM METRICS INDEXES" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
		mIndexList=($M_INDEX_LIST)
			for i in "${mIndexList[@]}" ; do
				echo "[$i]
datatype = metric
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf"
			done
	fi
}

sh_volumes() {
	if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_search_volume_indexes" ]; then
		mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_search_volume_indexes/local"
		mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_search_volume_indexes/metadata"
	fi
	echo "# SEARCH HEAD VOLUME SETTINGS
# In this example, the volume spec is only here to satisfy the
# \"volume:<name>\" tag in the indexes.conf. Indexes are shared between
# indexers and search heads, even though SH are not indexing any data
# locally. The SH uses this index list to validate the target of summary
# indexed data in the UI, or to provide typeahead for users trying to
# search for \"index=...\".
# In this instance, we do *not* use a maxVolumeDataSizeMB, because it
# doesn't matter.
# See also: org_full_indexes, org_indexer_volume_indexes

# One Volume for Hot and Cold
[volume:primary]
path = \$SPLUNK_HOME/splunk/var/lib/splunk

[volume:cold]
path = \$SPLUNK_HOME/splunk/var/lib/splunk
" >  "${PWD}/${ORGANIZATION}/${ORGANIZATION}_search_volume_indexes/local/indexes.conf"
}

hec_inputs() {
	if [ ! -d "${PWD}/${ORGANIZATION}/${ORGANIZATION}_hec_inputs" ]; then
		mkdir -p "${PWD}/${ORGANIZATION}/${ORGANIZATION}_hec_inputs/local"
		mkdir "${PWD}/${ORGANIZATION}/${ORGANIZATION}_hec_inputs/metadata"
	fi
	echo "[http]
disabled = 0
" >  "${PWD}/${ORGANIZATION}/${ORGANIZATION}_hec_inputs/local/inputs.conf"
	case "$SC4S_INSTALL" in
		[Yy]* )
			echo "[http://SC4SEvents]
token = $SC4S_TOKEN
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_hec_inputs/local/inputs.conf"
			;;
		* )
	esac
	case "$SOAR_INSTALL" in
		[Yy]* )
			echo "[http://SOAREvents]
token = $SOAR_TOKEN
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_hec_inputs/local/inputs.conf"
			;;
		* )
	esac
}

create_app_and_meta() {
	cd ${ORGANIZATION}
	APP_LIST=($(ls | grep ${ORGANIZATION} | grep -v .sh | grep -v .tgz | grep -v .txt | grep -v .conf | grep -v .yml))
	for i in "${APP_LIST[@]}" ; do
		echo "[install]
state = enabled

[package]
check_for_updates = false

[ui]
is_visible = false
is_manageable = false
" > "$i/local/app.conf"

		echo "[]
access = read : [ * ], write : [ admin ]
export = system
" > "$i/metadata/local.meta"
	done
}

user_seed() {
	echo "[user_info]
USERNAME=$SPLUNKADMIN
PASSWORD=$ADMINPASS" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_user-seed.conf"
}

shc_bootstrap() {
	if [ -z ${SPLUNK_HOME} ]; then
		echo "------------------------------------------------------------------"
		echo "Splunk installation directory wasn't defined the in ${ORGANIZATION}_variables.sh"
		read -er -p 'Enter the installation directory of Splunk: ' -i "/opt" SPLUNK_HOME
		echo "------------------------------------------------------------------"
		echo "Re-run the variable generation option to permanently add the variable to the file."
	fi
	SHC_MEMBERS=($SHC_MEMBERS)
	for i in "${SHC_MEMBERS[@]}" ; do
		BASE="https://$i:$MGMT_PORT"
		if [ ! -z "$MEMBER_LIST" ]; then
			MEMBER_LIST="$MEMBER_LIST,$BASE"
		else
			MEMBER_LIST="$BASE"
		fi
	done
	echo "------------------------------------------------------------------
## Use this command on the deployer to initialize configuration to be used as the deployer
------------------------------------------------------------------

$SPLUNK_HOME/splunk/bin/splunk init shcluster-config -auth $SPLUNKADMIN:$ADMINPASS -secret $SHC_P4SK
$SPLUNK_HOME/splunk/bin/splunk restart

------------------------------------------------------------------
## Use this command on each member to initialize the member to be used in searh head clustering
------------------------------------------------------------------

$SPLUNK_HOME/splunk/bin/splunk init shcluster-config -auth $SPLUNKADMIN:$ADMINPASS -mgmt_uri https://\$HOSTNAME:$MGMT_PORT -replication_port $SHC_REP_PORT -replication_factor 2 -conf_deploy_fetch_url https://$SHC_DEPLOYER_HOST:$MGMT_PORT -secret $SHC_P4SK -shcluster_label $SHC_LABEL
$SPLUNK_HOME/splunk/bin/splunk restart

------------------------------------------------------------------
## Use this command on ONE member to bootstrap it into the cluster as the captain and complete the initialization
------------------------------------------------------------------

$SPLUNK_HOME/splunk/bin/splunk bootstrap shcluster-captain -servers_list \"$MEMBER_LIST\" -auth $SPLUNKADMIN:$ADMINPASS
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_shcluster_bootstrap.txt"
}

archive() {
	echo "------------------------------------------------------------------"
	echo "Base apps for ${ORGANIZATION} have been created!"
	echo "------------------------------------------------------------------"
	read -p 'Do you want to tar up all the apps that were created? [Y/N] ' ARCHIVE
	case $ARCHIVE in
		[Yy]* )
			echo "------------------------------------------------------------------"
			DATE=$(date +%Y%m%d)
			cd "${PWD}/${ORGANIZATION}"
			tar -cvzf "./${ORGANIZATION}_baseapps_${DATE}.tgz" "${ORGANIZATION}_user-seed.conf" "${ORGANIZATION}_shcluster_bootstrap.txt" "${ORGANIZATION}_copy_apps.txt" ${ORGANIZATION}_*
			echo "------------------------------------------------------------------"
			echo "${ORGANIZATION}_baseapps_${DATE}.tgz created..."
			echo "------------------------------------------------------------------"
			;;
		[*] )
			echo "------------------------------------------------------------------"
			echo "Skipping archive..."
			echo "------------------------------------------------------------------"
	esac
}

fast_archive() {
	echo "------------------------------------------------------------------"
	DATE=$(date +%Y%m%d)
	cd "${PWD}/${ORGANIZATION}"
	if [ -f "${PWD}/${ORGANIZATION}/${ORGANIZATION}_baseapps_${DATE}.tgz" ]; then
		rm "${PWD}/${ORGANIZATION}/${ORGANIZATION}_baseapps_${DATE}.tgz"
	fi
	tar -cvzf "./${ORGANIZATION}_baseapps_${DATE}.tgz" "${ORGANIZATION}_user-seed.conf" "${ORGANIZATION}_shcluster_bootstrap.txt" "${ORGANIZATION}_copy_apps.txt" ${ORGANIZATION}_*
	echo "------------------------------------------------------------------"
	echo "${ORGANIZATION}_baseapps_${DATE}.tgz created..."
	echo "------------------------------------------------------------------"
}

show_passes() {
	if [ -f "${PWD}/${ORGANIZATION}_variables.sh" ]; then
		source "${PWD}/${ORGANIZATION}_variables.sh"
		echo "------------------------------------------------------------------"
		echo "################### pass4SymmKey Configurations ##################"
		echo "If there are blank values, the pass4SymmKey wasn't configured."
		echo "------------------------------------------------------------------"
		echo "Indexer Cluster:		$CM_P4SK"
		echo "Indexer Discovery:		$CM_ID_P4SK"
		echo "Search Head Cluster:		$SHC_P4SK"
	else
		echo "------------------------------------------------------------------"
		echo "The '${ORGANIZATION}_variables.sh' script has not been created yet.
There are no pass4SymmKey's on file."
		exit
	fi
}

app_copy() {
	if [ -z "${SPLUNK_HOME}" ]; then
		echo "------------------------------------------------------------------"
		echo "Splunk installation directory wasn't defined the in ${ORGANIZATION}_variables.sh"
		read -er -p 'Enter the installation directory of Splunk: ' -i "/opt" SPLUNK_HOME
		echo "------------------------------------------------------------------"
		echo "Re-run the variable generation option to permanently add the variable to the file."
	fi
	if [ "${IDC}" == "y" ]; then
		OUTPUTS_APP=" ${ORGANIZATION}_cluster_forwarder_outputs "
	else
		OUTPUTS_APP=" ${ORGANIZATION}_all_forwarder_outputs "
	fi
	if [ "${S2_INSTALL}" == "y" ]; then
		S3_VOLUME_APP=" ${ORGANIZATION}_indexer_s3volume_indexes "
	fi
	if [ "$SAI_INSTALL" == "y" ] || [ "$SC4S_INSTALL" == "y" ] || [ "$SOAR_INSTALL" == "y" ]; then
		HEC_APP=" ${ORGANIZATION}_hec_inputs "
	fi

		echo "------------------------------------------------------------------
Use the below commands on the specified servers to get apps staged in the proper places.
Note: This uses the default installation path of Splunk so adjust the destination accordingly.
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_copy_apps.txt"
	if [ "$IDC" == "y" ]; then
		echo "------------------------------------------------------------------
Cluster manager
------------------------------------------------------------------
cp -R ${ORGANIZATION}_all_deploymentclient ${ORGANIZATION}_full_license_server ${ORGANIZATION}_cluster_forwarder_outputs ${ORGANIZATION}_cluster_manager_base ${SPLUNK_HOME}/splunk/etc/apps
cp -R ${ORGANIZATION}_full_license_server ${ORGANIZATION}_indexer_base ${ORGANIZATION}_all_indexes ${ORGANIZATION}_all_indexes ${ORGANIZATION}_indexer_volume_indexes${HEC_APP}${S3_VOLUME_APP}${SPLUNK_HOME}/splunk/etc/master-apps

------------------------------------------------------------------
Clustered Indexers
------------------------------------------------------------------
cp -R ${ORGANIZATION}_cluster_indexer_base ${SPLUNK_HOME}/splunk/etc/apps
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_copy_apps.txt"
	else
		echo "------------------------------------------------------------------
Distributed Indexers
------------------------------------------------------------------
cp -R ${ORGANIZATION}_all_deploymentclient ${SPLUNK_HOME}/splunk/etc/apps
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_copy_apps.txt"
	fi
	if [ "$SHC" == "y" ]; then
		echo "------------------------------------------------------------------
Deployer
------------------------------------------------------------------
cp -R ${ORGANIZATION}_all_deploymentclient ${ORGANIZATION}_full_license_server${OUTPUTS_APP}${SPLUNK_HOME}/splunk/etc/apps
cp -R ${ORGANIZATION}_full_license_server ${ORGANIZATION}_all_indexes ${ORGANIZATION}_search_volume_indexes ${ORGANIZATION}_cluster_search_base${OUTPUTS_APP}${SPLUNK_HOME}/splunk/etc/shcluster/apps
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_copy_apps.txt"
	else
		echo "------------------------------------------------------------------
Search Heads
------------------------------------------------------------------
cp -R ${ORGANIZATION}_all_deploymentclient ${SPLUNK_HOME}/splunk/etc/apps
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_copy_apps.txt"
	fi
	if [ "$MULTISITE" == "y" ]; then
		echo "------------------------------------------------------------------
Considerations for Multisite Architectures
------------------------------------------------------------------
Since your organization is utilizing multisite, you'll need to utilize the additional apps to designate which site the indexers are a part of.
The same apps can be used on forwarders to determine which indexers at which site data is sent to.

" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_copy_apps.txt"
		MS_APP_LIST=($(ls | grep "${ORGANIZATION}" | grep -v .sh | grep "_site"))
		for i in "${MS_APP_LIST[@]}"; do
			SITE_NUMBER=$(echo $i | sed "s/${ORGANIZATION}_cluster_indexer_//")
		echo "------------------------------------------------------------------
Indexers - $SITE_NUMBER
------------------------------------------------------------------
cp -R $i ${SPLUNK_HOME}/splunk/etc/apps
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_copy_apps.txt"
		done
		if [ "$SEARCH_AFFINITY" == "y" ]; then
			echo "------------------------------------------------------------------
Note about Search Heads and Search Affinity
------------------------------------------------------------------
Since this organization will be utilizing search affinity, be sure to edit the local
version of \"server.conf\" on each member and add the site location for each search
head in the general stanza.

Example:

[general]
site = site1
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_copy_apps.txt"
		fi
	fi
	echo "------------------------------------------------------------------
Deployment Server
------------------------------------------------------------------
The deployment server will handle all configurations for forwarders and, in some situations,
major components of the Splunk infrastructure. The basic \"${ORGANIZATION}_serverclass.conf\" can be used to
ensure the apps are not removed from newly-established connections.

cp -R ${ORGANIZATION}_all_deploymentclient ${SPLUNK_HOME}/splunk/etc/deployment-apps
cp ${ORGANIZATION}_serverclass.conf ${SPLUNK_HOME}/splunk/etc/system/local/serverclass.conf
" >> "${PWD}/${ORGANIZATION}/${ORGANIZATION}_copy_apps.txt"
}

serverclass() {
	if [ "${IDC}" == "y" ]; then
		OUTPUTS_APP="${ORGANIZATION}_cluster_forwarder_outputs "
	else
		OUTPUTS_APP="${ORGANIZATION}_all_forwarder_outputs "
	fi
	echo "[serverClass:All Forwarders]
whitelist.0 = *

[serverClass:All Forwarders:app:$OUTPUTS_APP]
restartSplunkWeb = 0
restartSplunkd = 1
stateOnClient = enabled

[serverClass:All Forwarders:app:${ORGANIZATION}_all_deploymentclient]
restartSplunkWeb = 0
restartSplunkd = 1
stateOnClient = enabled

[serverClass:All Linux]
machineTypesFilter = linux-x86_64
whitelist.0 = *

[serverClass:All Windows]
machineTypesFilter = windows-x64
whitelist.0 = *
" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_serverclass.conf"
}

spotcheck() {
	if [ "${IDC}" == "y" ]; then
		OUTPUTS_APP="${ORGANIZATION}_cluster_forwarder_outputs"
	else
		OUTPUTS_APP="${ORGANIZATION}_all_forwarder_outputs"
	fi
	clear
	echo "This selection will walk you though each of the configurations in the apps of importance."
	echo "------------------------------------------------------------------
Admin User Configuration - user-seed.conf
------------------------------------------------------------------"
	more "${PWD}/${ORGANIZATION}/${ORGANIZATION}_user-seed.conf"
	echo "------------------------------------------------------------------"
	read -p "Press [Enter] to continue..."
	clear
	echo "------------------------------------------------------------------
Deployment Client - ${ORGANIZATION}_all_deploymentclient
------------------------------------------------------------------"
	more "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_deploymentclient/local/deploymentclient.conf"
	echo "------------------------------------------------------------------"
	read -p "Press [Enter] to continue..."
	clear
	echo "------------------------------------------------------------------
License manager - ${ORGANIZATION}_full_license_server
------------------------------------------------------------------"
	more "${PWD}/${ORGANIZATION}/${ORGANIZATION}_full_license_server/local/server.conf"
	echo "------------------------------------------------------------------"
	read -p "Press [Enter] to continue..."
	clear
	echo "------------------------------------------------------------------
Forwarder Outputs - ${OUTPUTS_APP}
------------------------------------------------------------------"
	echo "outputs.conf"
	echo "------------------------------------------------------------------"
	cat "${PWD}/${OUTPUTS_APP}/local/outputs.conf" | more
	echo "------------------------------------------------------------------"
	echo "limits.conf"
	echo "------------------------------------------------------------------"
	more "${PWD}/${OUTPUTS_APP}/local/limits.conf"
	echo "------------------------------------------------------------------"
	read -p "Press [Enter] to continue..."
	clear
	if [ "${IDC}" == "y" ]; then
		echo "------------------------------------------------------------------
Cluster manager - ${ORGANIZATION}_cluster_manager_base
------------------------------------------------------------------"
		more "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_manager_base/local/server.conf"
		echo "------------------------------------------------------------------"
		read -p "Press [Enter] to continue..."
		clear
		echo "------------------------------------------------------------------
Index Cluster Member - ${ORGANIZATION}_cluster_indexer_base
------------------------------------------------------------------"
		more "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_indexer_base/local/server.conf"
		echo "------------------------------------------------------------------"
		read -p "Press [Enter] to continue..."
		clear
		echo "------------------------------------------------------------------
Search Head Cluster Member - ${ORGANIZATION}_cluster_search_base
------------------------------------------------------------------"
		if [ "$ES_INSTALL" == "y" ]; then
			echo "server.conf"
			echo "------------------------------------------------------------------"
			cat "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/local/server.conf"
			echo "------------------------------------------------------------------"
			echo "web.conf"
			echo "------------------------------------------------------------------"
			more "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/local/web.conf"
			echo "------------------------------------------------------------------"
			read -p "Press [Enter] to continue..."
			clear
		else
			more "${PWD}/${ORGANIZATION}/${ORGANIZATION}_cluster_search_base/local/server.conf"
			echo "------------------------------------------------------------------"
			read -p "Press [Enter] to continue..."
			clear
		fi
	fi
	echo "------------------------------------------------------------------
Indexer Inputs - ${ORGANIZATION}_indexer_base
------------------------------------------------------------------"
	echo "inputs.conf"
	echo "------------------------------------------------------------------"
	cat "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_base/local/inputs.conf"
	echo "------------------------------------------------------------------"
	echo "web.conf"
	echo "------------------------------------------------------------------"
	more "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_base/local/web.conf"
	echo "------------------------------------------------------------------"
	read -p "Press [Enter] to continue..."
	clear
	if [ "$SC4S_INSTALL" == "y" ] || [ "$SOAR_INSTALL" == "y" ]; then
		echo "------------------------------------------------------------------
HEC Inputs - ${ORGANIZATION}_hec_inputs
------------------------------------------------------------------"
		more "${PWD}/${ORGANIZATION}/${ORGANIZATION}_hec_inputs/local/inputs.conf"
		echo "------------------------------------------------------------------"
		read -p "Press [Enter] to continue..."
		clear
	fi
	echo "------------------------------------------------------------------
Indexer Volume Configurations - ${ORGANIZATION}_indexer_volume_indexes
------------------------------------------------------------------"
	more "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_volume_indexes/local/indexes.conf"
	echo "------------------------------------------------------------------"
	read -p "Press [Enter] to continue..."
	clear
	echo "------------------------------------------------------------------
Search Head Volume Configurations - ${ORGANIZATION}_search_volume_indexes
------------------------------------------------------------------"
	more "${PWD}/${ORGANIZATION}/${ORGANIZATION}_search_volume_indexes/local/indexes.conf"
	echo "------------------------------------------------------------------"
	read -p "Press [Enter] to continue..."
	clear
	if [ "$S2_INSTALL" == "y" ]; then
		echo "------------------------------------------------------------------
SmartStore Configuration - ${ORGANIZATION}_indexer_s3volume_indexes
------------------------------------------------------------------"
		read -p "Press [Enter] to see the configurations"
		more "${PWD}/${ORGANIZATION}/${ORGANIZATION}_indexer_s3volume_indexes/local/indexes.conf"
		echo "------------------------------------------------------------------"
		read -p "Press [Enter] to continue..."
		clear
	fi
	echo "------------------------------------------------------------------
Index Configurations - ${ORGANIZATION}_all_indexes
------------------------------------------------------------------"
	INDEX_LC=$(cat "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf" | wc -l)
	INDEX_LC=$(( $INDEX_LC-64 ))
	read -p "Press [Enter] to see the configurations"
	tail -n "${INDEX_LC}" "${PWD}/${ORGANIZATION}/${ORGANIZATION}_all_indexes/local/indexes.conf" | more
	echo "------------------------------------------------------------------"
}

clean() {
	echo "------------------------------------------------------------------"
	echo "Cleaning out current apps for ${ORGANIZATION}..."
	find "${PWD}" -type d -name "${ORGANIZATION}*" -exec rm -rf {} \; > /dev/null 2>&1
	rm -rf "${PWD}/${ORGANIZATION}/${ORGANIZATION}_user-seed.conf" "${PWD}/${ORGANIZATION}/${ORGANIZATION}_shcluster_bootstrap.txt" "${PWD}/${ORGANIZATION}/${ORGANIZATION}_copy_apps.txt" > /dev/null 2>&1
	echo "------------------------------------------------------------------"
	PS3='Please enter your choice: '
}

splunk_passwords() {
	echo "------------------------------------------------------------------"
	echo "### ${ORGANIZATION}_splunk_passwords.yml
###
### DON'T FORGET TO VAULT ENCRYPT
###
### ansible-vault encrypt ${ORGANIZATION}_splunk_passwords.yml

######### Required fields for this repository #########

## Splunk local admin password for administrator account created when Splunk is installed
splunkAdminPassword: $ADMINPASS

## Splunk search head cluster pass4SymmKey for configuring search head cluster members of a single search head cluster.
shcP4SK: $SHC_P4SK

## Splunk indexer cluster pass4SymmKey values for the cluster and indexer discovery
idxClusterPass4SymmKey: $CM_P4SK

idxDiscoveryPass4SymmKey: $CM_ID_P4SK

## Version control details
gituser: $VC_USER

gitpass: $VC_PASSWORD
######### End of required passwords #########" > "${PWD}/${ORGANIZATION}/${ORGANIZATION}_splunk_passwords.yml"
	echo "${ORGANIZATION}_splunk_passwords.yml created! Be sure to encrpyt the file with ansible-vault before using."
	echo "Run command: ansible-vault encrypt ${ORGANIZATION}_splunk_passwords.yml"
	echo "------------------------------------------------------------------"
}

clear
echo "------------------------------------------------------------------"
echo "Greetings, programs!"
echo "This script will generate your organization's base apps"
echo "according to Splunk PS best practices."
echo "------------------------------------------------------------------"
echo "   ________________________________           "
echo "  /                                \\         "
echo "  |   The Notorious B.I.G D.A.T.A   |         "
echo "  \\______________________________ /\\        "
echo "                             ()    \\\\       "
echo "                               O    \\\\  .   "
echo "                                 o  |\\\\/|   "
echo "                                    / \" '\\  "
echo "                                    . .   .   "
echo "                                   /    ) |   "
echo "                                  '  _.'  |   "
echo "                                  '-'/    \\  "
echo "------------------------------------------------------------------"
PS3='Please enter your choice: '
options=("Generate variables.sh" "Create Apps" "Archive Apps" "Show pass4SymmKey's" "Config Checker" "Clean" "Generate Ansible vault" "Quit")
select opt in "${options[@]}"
do
	case $opt in
		"Generate variables.sh")
			generate_variables
			break
			;;
		"Create Apps")
			call_variables
			deploymentclient
			license_manager
			outputs
			ms_site_definitions
			cm_base
			sh_cm_member
			indexer_cm_member
			indexer_base
			all_indexes
			indexer_volumes
			if [ "$S2_INSTALL" == "y" ]; then
				indexer_s2_volumes
			fi
			sh_volumes
			if [ "$SC4S_INSTALL" == "y" ] || [ "$SOAR_INSTALL" == "y" ]; then
				hec_inputs
			fi
			user_seed
			if [ "$SHC" == "y" ]; then
				shc_bootstrap
			fi
			serverclass
			app_copy
			create_app_and_meta
			archive
			break
			;;
		"Archive Apps")
			call_variables
			fast_archive
			break
			;;
		"Show pass4SymmKey's")
			call_variables
			show_passes
			break
			;;
		"Config Checker")
			call_variables
			spotcheck
			break
			;;
		"Clean")
			call_variables
			clean
			;;
		"Generate Ansible vault")
			call_variables
			splunk_passwords
			break
			;;
		"Quit")
			exit
			;;
		*)
			echo "Please select a vaild option."
			;;
	esac
done
