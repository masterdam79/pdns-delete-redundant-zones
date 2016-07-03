#!/bin/bash

HOSTNAME=$(hostname -f)
DATE=$(date +"%Y-%m-%d")
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
DATABASE="powerdns"
# Make backup of the powerdns database
mysqldump ${DATABASE} > /root/${DATABASE}-${TIMESTAMP}-$0.sql

# Get list of domains on this server.
