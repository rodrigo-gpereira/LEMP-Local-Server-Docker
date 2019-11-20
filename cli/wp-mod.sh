#!/bin/bash
#
# Este script repara as permissões de acesso aos arquivos do WordPress, 
# em conformidade com as recomendações de segurança do Codex: 
# http://codex.wordpress.org/Hardening_WordPress#File_permissions
#
# Autor: Michael Conigliaro <mike [at] conigliaro [dot] org>
# Tradução: Otoniel Feliciano
#
# DEFINIR VARIAVEIS
WP_OWNER=www-data	#==> proprietário wordpress
WP_GROUP=www-data	#==> grupo wordpress
WS_GROUP=www-data	#==> grupo de servidores web
WP_ROOT=$1		#==> diretório raiz do wordpress
# FIM - DEFINIR VARIAVEIS
 
# redefinir para padrões seguros
find ${WP_ROOT} -exec chown ${WP_OWNER}:${WP_GROUP} {} \;
find ${WP_ROOT} -type d -exec chmod 755 {} \;
find ${WP_ROOT} -type f -exec chmod 644 {} \;
 
# permitir (e impedir o resto do mundo) que o wordpress gerencie o arquivo wp-config.php 
chgrp ${WS_GROUP} ${WP_ROOT}/wp-config.php
chmod 660 ${WP_ROOT}/wp-config.php
 
# permitir que o wordpress gerencie o arquivo .htaccess
touch ${WP_ROOT}/.htaccess
chgrp ${WS_GROUP} ${WP_ROOT}/.htaccess
chmod 664 ${WP_ROOT}/.htaccess
 
# permitir que o wordpress gerencie o diretório wp-content
find ${WP_ROOT}/wp-content -exec chgrp ${WS_GROUP} {} \;
find ${WP_ROOT}/wp-content -type d -exec chmod 775 {} \;
find ${WP_ROOT}/wp-content -type f -exec chmod 664 {} \;
