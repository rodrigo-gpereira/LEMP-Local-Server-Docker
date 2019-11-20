#!/usr/bin/env bash
#
# Nginx - new server block

# Functions
ok() { echo -e '\e[32m'$1'\e[m'; } # Green
die() { echo -e '\e[1;31m'$1'\e[m'; exit 1; }


# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."

echo -e "Insira o Hostname:"
read HOSTNAME
echo -e "Insira o Subdominio"
read SUBDOMAIN

#Remover os arquivos de modelo CRS.CNF e .EXT
./tunnel/loclx tunnel http --host-header $HOSTNAME --to 192.168.0.30:80 --subdomain $SUBDOMAIN

ok "Site Expose $1"
