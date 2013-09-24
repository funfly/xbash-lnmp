#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

project_name="xbash-lnmp 1.0";

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install $project_name" 
    exit 1
fi

clear
echo "========================================================================="
echo "$project_name for CentOS/RadHat Written by funfly, Email:funfly@xbash.cn"
echo "========================================================================="
echo "A tool to auto-compile & install nginx-1.5.4 + mysql-5.6.13 + php-5.5.3 on Linux "
echo ""
echo "For more information please visit http://www.xbash.cn/"
echo "========================================================================="
cur_dir=$(pwd)

if [ "$1" != "--help" ]; then

default_server_name="webServer001"

echo "Please input your server name:"
read -p "(Default server name:$default_server_name):" server_name
if [ "$server_name" = "" ]; then
    server_name=$default_server_name
fi
echo "==========================="
echo server name="$server_name"
echo "==========================="

default_password="123456";

echo "Please input mysql root password:"
read -p "(Default mysql root password:$default_password):" password
if [ "$password" = "" ]; then
    password=$default_password
fi
echo "==========================="
echo mysql root password="$password"
echo "==========================="

get_char()
{
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}
echo ""
echo "Press any key to start..."
char=`get_char`

rpm -qa|grep  httpd
rpm -e httpd
rpm -qa|grep mysql
rpm -e mysql
rpm -qa|grep php
rpm -e php

yum -y remove httpd
yum -y remove php
yum -y remove mysql-server mysql
yum -y remove php-mysql

yum -y install yum-fastestmirror
yum -y install wget make gcc gcc-c++ g77 perl autoconf automake cmake unzip libaio libaio-devel bison ncurses-devel libxslt libxslt-devel libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel gd2 gd2-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel bzip2 bzip2-devel libevent libevent-devel curl curl-devel openssl openssl-devel glibc glibc-devel 

#Set hostname
sed -i 's/HOSTNAME=localhost.localdomain/HOSTNAME='$server_name'/g' /etc/sysconfig/network

#Set iptables
/sbin/iptables -I INPUT -p tcp --dport 3306 -j ACCEPT
/sbin/iptables -I INPUT -p tcp --dport 80 -j ACCEPT
/etc/rc.d/init.d/iptables save
/etc/init.d/iptables restart

#Set timezone
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo "============================ntp install=================================="
yum install -y ntp
sed -i 's/server 0.centos.pool.ntp.org/server 1.cn.pool.ntp.org/g' /etc/ntp.conf
sed -i 's/server 1.centos.pool.ntp.org/server 1.asia.pool.ntp.org/g' /etc/ntp.conf
sed -i 's/server 2.centos.pool.ntp.org/server 2.asia.pool.ntp.org/g' /etc/ntp.conf
ntpdate 1.cn.pool.ntp.org

cd $cur_dir
echo "============================check files=================================="
if [ -s pcre-8.21.tar.gz ]; then
    echo "pcre-8.21.tar.gz [found]"
    else
    echo "Error: pcre-8.21.tar.gz not found!!!download now......"
    wget -c ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.21.tar.gz
fi

if [ -s nginx-1.5.4 ]; then
    echo "nginx-1.5.4 [found]"
    else
    echo "Error: nginx-1.5.4 not found!!!download now......"
    wget -c http://nginx.org/download/nginx-1.5.4.tar.gz
fi

if [ -s mysql-5.6.13-linux-glibc2.5-i686.tar.gz ]; then
    echo "mysql-5.6.13-linux-glibc2.5-i686.tar.gz [found]"
    else
    echo "Error: mysql-5.6.13-linux-glibc2.5-i686.tar.gz not found!!!download now......"
    wget -c wget http://cdn.mysql.com/Downloads/MySQL-5.6/mysql-5.6.13-linux-glibc2.5-i686.tar.gz
fi

if [ -s libmcrypt-2.5.7.tar.gz ]; then
    echo "libmcrypt-2.5.7.tar.gz [found]"
    else
    echo "Error: libmcrypt-2.5.7.tar.gz not found!!!download now......"
    wget -c ftp://mcrypt.hellug.gr/pub/crypto/mcrypt/libmcrypt/libmcrypt-2.5.7.tar.gz
fi

if [ -s php-5.5.3.tar.gz ]; then
    echo "php-5.5.3.tar.gz [found]"
    else
    echo "Error: php-5.5.3.tar.gz not found!!!download now......"
    wget -c http://cn2.php.net/distributions/php-5.5.3.tar.gz
fi

cd $cur_dir
tar -xvf pcre-8.21.tar.gz
cd pcre-8.21
./configure
make
make install

cd $cur_dir
tar -xvf libmcrypt-2.5.7.tar.gz
cd libmcrypt-2.5.7
./configure
make
make install

echo "============================nginx install=================================="
groupadd www
useradd www -g www -M -s /sbin/nologin

cd $cur_dir
tar -xvf nginx-1.5.4.tar.gz
cd nginx-1.5.4
./configure  --user=www --group=www --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_realip_module --with-http_image_filter_module 
make
make install

cd $cur_dir
rm -rf /usr/local/nginx/conf/nginx.conf
cp conf/nginx.conf  /usr/local/nginx/conf/nginx.conf

rm -rf  /usr/local/nginx/html/phpinfo.php
cp phpinfo.php  /usr/local/nginx/html/

if [ ! `grep -l "/usr/local/nginx/sbin/nginx"    '/etc/rc.local'` ]; then
    echo "/usr/local/nginx/sbin/nginx" >> /etc/rc.local
fi

echo "============================mysql install=================================="
groupadd mysql
useradd mysql -g mysql -M -s /sbin/nologin

rm -rf /etc/my.cnf

cd $cur_dir
tar -xvf mysql-5.6.13-linux-glibc2.5-i686.tar.gz
mv mysql-5.6.13-linux-glibc2.5-i686 /usr/local/mysql

chown -R mysql.mysql /usr/local/mysql
cd /usr/local/mysql/scripts
./mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data

cd /usr/local/mysql/support-files
rm -rf /etc/init.d/mysqld
cp mysql.server /etc/init.d/mysqld
chmod 755 /etc/init.d/mysqld
chkconfig --add mysqld
chkconfig mysqld on

/etc/rc.d/init.d/mysqld start
/usr/local/mysql/bin/mysqladmin -u root password $password
cat > /tmp/init_mysql_privileges.sql<<EOF
grant all privileges on *.* to root@'%' identified by '$password';
use mysql;
update user set password=password('$password') where user='root';
delete from user where not (user='root') ;
delete from user where user='root' and password='';
flush privileges;
EOF
/usr/local/mysql/bin/mysql -u root -p$password < /tmp/init_mysql_privileges.sql
rm -f /tmp/init_mysql_privileges.sql

echo "============================php install=================================="

if [ ! `grep -l "/lib"    '/etc/ld.so.conf'` ]; then
    echo "/lib" >> /etc/ld.so.conf
fi

if [ ! `grep -l '/usr/lib'    '/etc/ld.so.conf'` ]; then
    echo "/usr/lib" >> /etc/ld.so.conf
fi

if [ -d "/usr/lib64" ] && [ ! `grep -l '/usr/lib64'    '/etc/ld.so.conf'` ]; then
    echo "/usr/lib64" >> /etc/ld.so.conf
fi

if [ ! `grep -l '/usr/local/lib'    '/etc/ld.so.conf'` ]; then
    echo "/usr/local/lib" >> /etc/ld.so.conf
fi

if [ ! `grep -l "/usr/local/mysql/lib"    '/etc/ld.so.conf'` ]; then
    echo "/usr/local/mysql/lib" >> /etc/ld.so.conf
fi

ldconfig

cd $cur_dir
tar -xvf php-5.5.3.tar.gz
cd php-5.5.3
./configure \
--prefix=/usr/local/php \
--with-config-file-path=/usr/local/php/etc \
--with-mysql=/usr/local/mysql \
--with-pdo-mysql=/usr/local/mysql \
--with-mysqli \
--with-gd \
--with-openssl \
--with-jpeg-dir \
--with-png-dir \
--with-freetype-dir \
--with-zlib \
--with-gettext \
--with-curl \
--with-iconv \
--with-bz2 \
--with-mcrypt \
--with-pear \
--with-xsl \
--with-libxml-dir=/usr \
--disable-rpath \
--enable-opcache \
--enable-pcntl \
--enable-mbregex \
--enable-fpm \
--enable-exif \
--enable-calendar \
--enable-zip \
--enable-gd-native-ttf \
--enable-xml \
--enable-sockets \
--enable-mbstring=all \
--enable-bcmath \
--enable-inline-optimization \
--enable-ftp ;
make
make install

cd $cur_dir

rm -rf /usr/local/php/etc/php.ini
cp conf/php.ini  /usr/local/php/etc/php.ini

rm -rf /usr/local/php/etc/php-fpm.conf
cp conf/php-fpm.conf  /usr/local/php/etc/php-fpm.conf

if [ ! `grep -l "/usr/local/php/sbin/php-fpm"    '/etc/rc.local'` ]; then
    echo "/usr/local/php/sbin/php-fpm" >> /etc/rc.local
fi

echo "============================phpMyAdmin install================================="
cd $cur_dir
unzip phpMyAdmin-4.0.5-all-languages.zip
mv phpMyAdmin-4.0.5-all-languages /usr/local/nginx/html/pma
chown www:www -R  /usr/local/nginx/html/pma

echo "============================start service================================="
/usr/local/php/sbin/php-fpm
/usr/local/nginx/sbin/nginx

echo "===================================== set conf ==================================="
cat >>/etc/security/limits.conf<<EOF
* soft nofile 65535
* hard nofile 65535
EOF

cat >>/etc/sysctl.conf<<EOF
net.ipv4.tcp_max_syn_backlog = 65536
net.core.netdev_max_backlog =  32768
net.core.somaxconn = 32768

net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2

net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_len = 1
net.ipv4.tcp_tw_reuse = 1

net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800

net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 120
net.ipv4.ip_local_port_range = 1024  65535

fs.file-max=65535
EOF

/sbin/sysctl -p

echo "===================================== Check install ==================================="
clear

if [ -s /usr/local/nginx ]; then
    echo "/usr/local/nginx [found]"
    else
    echo "Error: /usr/local/nginx not found!!!"
fi

if [ -s /usr/local/mysql ]; then
    echo "/usr/local/mysql [found]"
    else
    echo "Error: /usr/local/mysql not found!!!"
fi

if [ -s /usr/local/php ]; then
    echo "/usr/local/php [found]"
    else
    echo "Error: /usr/local/php not found!!!"
fi

if [ -s /usr/local/nginx ] && [ -s /usr/local/mysql ] && [ -s /usr/local/php ]; then

echo "Install $project_name completed! enjoy it."
echo "========================================================================="
echo "$project_name for CentOS/RadHat Written by funfly, Email:funfly@xbash.cn"
echo "========================================================================="
echo ""
echo "For more information please visit http://www.xbash.cn/"
echo ""
echo "mysql root password:$password"
echo "phpinfo : http://localhost/phpinfo.php "
echo "phpMyAdmin : http://localhost/pma/"
echo ""
echo "The path of some dirs:"
echo "web dir :    /usr/local/nginx/html"
echo "nginx dir:   /usr/local/nginx"
echo "mysql dir:   /usr/local/mysql"
echo "php dir:     /usr/local/php"
echo ""
echo "========================================================================="
netstat -ntl
else
    echo "Sorry,Failed to install $project_name"
    echo "Please visit http://www.xbash.cn/ feedback errors and logs."
fi
fi
 