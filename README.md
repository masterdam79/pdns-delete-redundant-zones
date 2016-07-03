# pdns-delete-redundant-zones

This repository just contains one script which will delete all redundant zones (e.g. zones whose authoritative nameserver is nog the host this script is ran on).

*Take precaution; I will not be held responsible for the effect this script has on your PDNS server*

## Compatibility
This script is built to run under de vollowing circumstances

* CentOS Linux release 7.2.1511 (Core) x86_64
* PowerDNS Authoritative Server 3.4.8

## Assumptions
This script assumes there is a file ```/root/.my.cnf``` which contains the root credentials for loggin into the database with all privileges.

Basically logging into the powerdns database should be no more than ```mysql powerdns```.

## Usage

This script is to be run from the directory where you cloned this repository

```bash
cd /path/to/repo/
sh pdns-delete-redundant-zones.sh
```
