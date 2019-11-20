#!/usr/bin/env bash
#
# Nginx - new server block

# Functions
ok() { echo -e '\e[32m'$1'\e[m'; } # Green
die() { echo -e '\e[1;31m'$1'\e[m'; exit 1; }

# Variables

NGINX_DIR='./nginx/sites'
WEB_DIR='./htdocs'

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
[ $# != "1" ] && die "Usage: $(basename $0) domainName"


#Remover os arquivos de modelo CRS.CNF e .EXT
rm $NGINX_DIR/${1//[-._]/}.conf
rm -r $WEB_DIR/$1/

ok "Site remove $1"
