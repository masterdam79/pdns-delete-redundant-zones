#!/bin/bash

HOSTNAME=$(hostname -f)
DATE=$(date +"%Y-%m-%d")
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
DATABASE="powerdns"

# Make backup of the powerdns database
mysqldump ${DATABASE} > /root/${DATABASE}-${TIMESTAMP}-$0.sql

# Get list of domains on this server.
DOMAINS=$(mysql powerdns -s -e "SELECT Name FROM domains;")
for DOMAIN in ${DOMAINS}; do
  echo ${DOMAIN}
  NSRECORDS=$(dig @8.8.8.8 ${DOMAIN} NS | grep ^${DOMAIN} | awk '{print $5}')
  for NSRECORD in ${NSRECORDS}; do
    echo ${NSRECORD::-1}
  done
done
