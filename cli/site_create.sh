#!/usr/bin/env bash
#
# Nginx - new server block

# Functions
ok() { echo -e '\e[32m'$1'\e[m'; } # Green
die() { echo -e '\e[1;31m'$1'\e[m'; exit 1; }

# Variables
NGINX_DIR='./nginx/sites'
WEB_DIR='./htdocs'
SSL_DIR='./ssl-root'
ROOTCA_PASS='Sofine19$INFO$'
USER='www-data'

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
[ $# != "1" ] && die "Usage: $(basename $0) domainName"

# Create nginx config file
cat > $NGINX_DIR/${1//[-._]/}.conf <<EOF
server {

	listen 80;
	listen 443 ssl;


        ssl_certificate /var/www/html/$1/ssl/${1//[-._]/}.crt; 
        ssl_certificate_key /var/www/html/$1/ssl/${1//[-._]/}.key;

	root /var/www/html/$1/public;
	index index.php index.html index.htm;

	# Acesse o site por http://localhost/
	server_name $1 www.$1;

	location / {
         try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

	location ~ \.php$ {
        try_files \$uri /index.php =404;
        fastcgi_pass php-fpm:9000;
        fastcgi_index index.php;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
	
    location ~ /\.ht {
        deny all;
    }
}

EOF

# Creating {public} directories
mkdir -p $WEB_DIR/$1/public
mkdir -p $WEB_DIR/$1/ssl

# Creating index.html file
cat > $WEB_DIR/$1/public/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
        <title>$1</title>
        <meta charset="utf-8" />
</head>
<body class="container">
        <header><h1>$1<h1></header>
        <div id="wrapper">

Hello World
</div>
        <footer>© $(date +%Y)</footer>
</body>
</html>
EOF

# Changing permissions
chown -R $USER:$USER $WEB_DIR/$1

# Create Certificate config

# SERVER.CSR.CNF
cat > $SSL_DIR/${1//[-._]/}.crs.cnf <<EOF

[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C=BR
ST=São Paulo
L=Vargem Grande Paulista
O=Infografic
OU=IF
emailAddress=dev@infografic.com.br
CN = $1

EOF

# V3.EXT
cat > $SSL_DIR/${1//[-._]/}.ext <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $1

EOF

#Generate Certificate

current_dir=$PWD

cd $SSL_DIR/

openssl req -new -sha256 -nodes -out ${1//[-._]/}.crs -newkey rsa:2048 -keyout ${1//[-._]/}.key -config <( cat ${1//[-._]/}.crs.cnf )
openssl x509 -passin pass:$ROOTCA_PASS -req -in ${1//[-._]/}.crs -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out ${1//[-._]/}.crt -days 500 -sha256 -extfile ${1//[-._]/}.ext

cd $current_dir

mv $SSL_DIR/${1//[-._]/}.crs $WEB_DIR/$1/ssl/
mv $SSL_DIR/${1//[-._]/}.key $WEB_DIR/$1/ssl/ 
mv $SSL_DIR/${1//[-._]/}.crt $WEB_DIR/$1/ssl/

#Remover os arquivos de modelo CRS.CNF e .EXT
rm $SSL_DIR/${1//[-._]/}.crs.cnf
rm $SSL_DIR/${1//[-._]/}.ext

ok "Site Created for $1"
