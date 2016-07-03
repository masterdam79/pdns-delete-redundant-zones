#!/bin/bash

ECHOGRAY() {
  echo -e "\e[1;30m$1\e[0m"
}

ECHORED() {
  echo -e "\e[1;31m$1\e[0m"
}

ECHOGREEN() {
  echo -e "\e[1;32m$1\e[0m"
}

ECHOYELLOW() {
  echo -e "\e[1;33m$1\e[0m"
}

ECHOBLUE() {
  echo -e "\e[1;34m$1\e[0m"
}

HOSTNAME=$(hostname -f)
DATE=$(date +"%Y-%m-%d")
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
DATABASE="powerdns"
LOGPATH="/root/"

# Make backup of the powerdns database
mysqldump ${DATABASE} > /root/${DATABASE}-${TIMESTAMP}-$0.sql
mysqldump --skip-extended-insert ${DATABASE} > /root/${DATABASE}-${TIMESTAMP}-$0-skip-extended-insert.sql

# Get list of domains on this server.
DOMAINS=$(mysql powerdns -s -e "SELECT Name FROM domains;" | egrep -v "^Name|arpa")
# Loop domains
for DOMAIN in ${DOMAINS}; do
  echo ""
  ECHOGREEN ${DOMAIN}
  # Query NS records @8.8.8.8 (Google DNS) and check how many records are returned
  NSRECORDS=$(dig @8.8.8.8 ${DOMAIN} NS | grep ^${DOMAIN} | awk '{print $5}' | sort)
  NSRECORDCOUNT=$(dig @8.8.8.8 ${DOMAIN} NS | grep ^${DOMAIN} | wc -l)
  if [[ ${NSRECORDCOUNT} == "0" ]]; then
    # If the domain has no NS records, just log to investigate later, do not delete the zone
    ECHOYELLOW "This domain appears not to have any NS records?"
    NOTDELETING="true"
    echo "${DOMAIN} - not deleted due to no NS records" >> ${DATABASE}-${TIMESTAMP}-$0.log
  else
    # The domain has NS records, loop them
    for NSRECORD in ${NSRECORDS}; do
      ECHOBLUE ${NSRECORD::-1}
      if [[ ${NSRECORD::-1} == ${HOSTNAME} ]]; then
        ECHOGRAY "${NSRECORD::-1} == ${HOSTNAME}"
        # If current NS record contains the hostname
        NOTDELETING="true"
      else
        NOTDELETING="false"
      fi
    done
  fi
  if [[ "${NOTDELETING}" == "true" ]]; then
    ECHORED "We're not deleting this zone"
    echo "${DOMAIN} - not deleted because ${NSRECORD::-1} == ${HOSTNAME}" >> ${DATABASE}-${TIMESTAMP}-$0.log
  else
    # Get domain ID
    DOMAINID=$(mysql powerdns -s -e "SELECT id FROM domains WHERE name = \"${DOMAIN}\"" | egrep -v "^id")
    ECHOYELLOW "We're deleting the zone with ID ${DOMAINID} and its records"
    echo "${DOMAIN} - deleted because NS records didn't match local hostname" >> ${DATABASE}-${TIMESTAMP}-$0.log
    ECHOGRAY "mysql powerdns -e \"DELETE FROM `records` WHERE `domain_id` = ${DOMAINID};\""
    # Output current records to log
    grep ${DOMAIN} /root/${DATABASE}-${TIMESTAMP}-$0-skip-extended-insert.sql
  fi
done
