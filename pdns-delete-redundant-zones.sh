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

# Make backup of the powerdns database
mysqldump ${DATABASE} > /root/${DATABASE}-${TIMESTAMP}-$0.sql

# Get list of domains on this server.
DOMAINS=$(mysql powerdns -s -e "SELECT Name FROM domains;")
# Loop domains
for DOMAIN in ${DOMAINS}; do
  ECHOGREEN ${DOMAIN}
  # Query NS records @8.8.8.8 (Google DNS) and check how many records are returned
  NSRECORDS=$(dig @8.8.8.8 ${DOMAIN} NS | grep ^${DOMAIN} | awk '{print $5}' | sort)
  NSRECORDCOUNT=$(dig @8.8.8.8 ${DOMAIN} NS | grep ^${DOMAIN} | wc -l)
  if [[ ${NSRECORDCOUNT} == "0" ]]; then
    # If the domain has no NS records, just log to investigate later, do not delete the zone
    ECHOYELLOW "This domain appears not to have any NS records?"
    NOTDELETING="true"
  else
    # The domain has NS records, loop them
    for NSRECORD in ${NSRECORDS}; do
      ECHOBLUE ${NSRECORD::-1}
      if [[ ${NSRECORD::-1} == ${HOSTNAME} ]]; then
        ECHOGRAY "${NSRECORD::-1} == ${HOSTNAME}"
        # If current NS record contains the hostname
        NOTDELETING="true"
      fi
    done
  fi
  if [[ "${NOTDELETING}" == "true" ]]; then
    ECHORED "We're not deleting this zone"
  else
    ECHOYELLOW "We're deleting this zone"
  fi
done
