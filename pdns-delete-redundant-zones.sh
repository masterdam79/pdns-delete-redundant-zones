#!/bin/bash

ECHOSILVER() {
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

ECHOFUCHSIA() {
  echo -e "\e[1;35m$1\e[0m"
}

ECHOCYAN() {
  echo -e "\e[1;36m$1\e[0m"
}

ECHOSILVER() {
  echo -e "\e[1;38m$1\e[0m"
}

HOSTNAME=$(hostname -f)
DATE=$(date +"%Y-%m-%d")
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
DATABASE="powerdns"
RESOLVER=$1

if [[ -z $1 ]]; then
  RESOLVER="8.8.8.8"
fi

# Make backup of the powerdns database
mysqldump ${DATABASE} > /root/${DATABASE}-${TIMESTAMP}-$0.sql
mysqldump --skip-extended-insert ${DATABASE} > /root/${DATABASE}-${TIMESTAMP}-$0-skip-extended-insert.sql

# Create some directories
mkdir -p /root/log
mkdir -p /root/restore

# Get list of domains on this server.
DOMAINS=$(mysql powerdns -s -e "SELECT Name FROM domains;" | egrep -v "^Name|arpa")
# Loop domains
for DOMAIN in ${DOMAINS}; do
  # Reset variable
  NOTDELETING=""
  echo ""
  ECHOGREEN ${DOMAIN}
  # Query NS records @8.8.8.8 (Google DNS) and check how many records are returned
  NSRECORDS=$(dig @${RESOLVER} ${DOMAIN} NS | grep ^${DOMAIN} | awk '{print $5}' | sort)
  NSRECORDCOUNT=$(dig @${RESOLVER} ${DOMAIN} NS | grep ^${DOMAIN} | wc -l)
  if [[ ${NSRECORDCOUNT} == "0" ]]; then
    # If the domain has no NS records, just log to investigate later, do not delete the zone
    ECHOYELLOW "This domain appears not to have any NS records?"
    NOTDELETING="true"
  else
    # The domain has NS records, loop them
    for NSRECORD in ${NSRECORDS}; do
      ECHOBLUE ${NSRECORD::-1}
      echo "${DOMAIN} - ${NSRECORD::-1}" >> /root/log/${DATABASE}-${TIMESTAMP}-$0.log
      if [[ "${NSRECORD::-1}" == "${HOSTNAME}" ]]; then
        ECHOFUCHSIA "${NSRECORD::-1} is ${HOSTNAME}"
        # If current NS record contains the hostname
        ECHOCYAN "BOOYA"
        NOTDELETING="true"
      fi
    done
  fi
  ECHOCYAN "${NOTDELETING}"
  if [[ "${NOTDELETING}" == "true" ]]; then
    ECHORED "We're not deleting this zone"
    if [[ ${NSRECORDCOUNT} -eq 0 ]]; then
      echo "${DOMAIN} - not deleted due to no NS records" >> /root/log/${DATABASE}-${TIMESTAMP}-$0.log
    else
      echo "${DOMAIN} - not deleted because ${NSRECORD::-1} == ${HOSTNAME}" >> /root/log/${DATABASE}-${TIMESTAMP}-$0.log
    fi
  else
    # Get domain ID
    DOMAINID=$(mysql powerdns -s -e "SELECT id FROM domains WHERE name = \"${DOMAIN}\"" | egrep -v "^id")
    ECHOYELLOW "We're deleting the zone with ID ${DOMAINID} and its records"
    echo "${DOMAIN} - deleted because NS records didn't match local hostname" >> /root/log/${DATABASE}-${TIMESTAMP}-$0.log
    ECHOSILVER "mysql powerdns -e \"DELETE FROM records WHERE domain_id = ${DOMAINID};\""
    ECHOSILVER "mysql powerdns -e \"DELETE FROM domains WHERE id = ${DOMAINID};\""
    # Output current records to log
    grep ${DOMAIN} /root/${DATABASE}-${TIMESTAMP}-$0-skip-extended-insert.sql >> /root/restore/${DOMAIN}-${TIMESTAMP}.sql
  fi
done
