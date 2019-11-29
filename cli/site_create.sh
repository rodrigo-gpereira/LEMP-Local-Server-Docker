#!/usr/bin/env bash
#
# Nginx - new server block

# Functions
ok() { echo -e '\e[32m'$1'\e[m'; } # Green
die() { echo -e '\e[1;31m'$1'\e[m'; exit 1; }

# Variables
NGINX_DIR='./nginx/sites'
WEB_DIR='./htdocs'
SSL_DIR='./ssl-rootCA'
USER='www-data'

echo -e "Insira a senha do certificado ROOTCA:"
read ROOTCA_PASS

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
[ $# != "1" ] && die "Usage: $(basename $0) domainName"

# Create nginx config file
cat > $NGINX_DIR/${1//[-._]/}.conf <<EOF
server {

	listen 80;
        listen [::]:80;
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /var/www/html/$1/ssl/${1//[-._]/}.crt; 
        ssl_certificate_key /var/www/html/$1/ssl/${1//[-._]/}.key;

	root /var/www/html/$1/public;
	index index.php index.html index.htm;

	# Acesse o site por http://localhost/
	server_name $1 www.$1;

        # enable session resumption to improve https performance
        # http://vincent.bernat.im/en/blog/2011-ssl-session-reuse-rfc5077.html
        ssl_session_cache shared:SSL:50m;
        ssl_session_timeout 1d;
        ssl_session_tickets off;

        # Diffie-Hellman parameter for DHE ciphersuites, recommended 2048 bits
        #ssl_dhparam /var/www/ssl-rootCA/dhparam.pem;

        # enables server-side protection from BEAST attacks
        # http://blog.ivanristic.com/2013/09/is-beast-still-a-threat.html
        ssl_prefer_server_ciphers on;
        # disable SSLv3(enabled by default since nginx 0.8.19) since it's less secure then TLS http://en.wikipedia.org/wiki/Secure_Sockets_Layer#SSL_3.0
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        # ciphers chosen for forward secrecy and compatibility
        # http://blog.ivanristic.com/2013/08/configuring-apache-nginx-and-openssl-for-forward-secrecy.html
        ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';

        # enable ocsp stapling (mechanism by which a site can convey certificate revocation information to visitors in a privacy-preserving, scalable manner)
        # http://blog.mozilla.org/security/2013/07/29/ocsp-stapling-in-firefox/
        resolver 8.8.8.8 8.8.4.4;
        ssl_stapling on;
        ssl_stapling_verify on; 

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

#Reinciar o serviço do nginx no container
docker-compose restart nginx

docker exec -it php-fpm /var/www/cli/setup-hosts-file.sh $1 a 