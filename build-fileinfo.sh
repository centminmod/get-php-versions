#!/bin/bash
##################################################
# build php fileinfo extension for each major PHP
# version 5.4, 5.5, 5.6, 7.0, 7.1, 7.2, 7.3
##################################################
SILENT='n'

CENTOSVER=$(awk '{ print $3 }' /etc/redhat-release)

if [ "$CENTOSVER" == 'release' ]; then
    CENTOSVER=$(awk '{ print $4 }' /etc/redhat-release | cut -d . -f1,2)
    if [[ "$(cat /etc/redhat-release | awk '{ print $4 }' | cut -d . -f1)" = '7' ]]; then
        CENTOS_SEVEN='7'
    fi
fi

if [[ "$(cat /etc/redhat-release | awk '{ print $3 }' | cut -d . -f1)" = '6' ]]; then
    CENTOS_SIX='6'
fi

# Check for Redhat Enterprise Linux 7.x
if [ "$CENTOSVER" == 'Enterprise' ]; then
    CENTOSVER=$(awk '{ print $7 }' /etc/redhat-release)
    if [[ "$(awk '{ print $1,$2 }' /etc/redhat-release)" = 'Red Hat' && "$(awk '{ print $7 }' /etc/redhat-release | cut -d . -f1)" = '7' ]]; then
        CENTOS_SEVEN='7'
        REDHAT_SEVEN='y'
    fi
fi

if [[ -f /etc/system-release && "$(awk '{print $1,$2,$3}' /etc/system-release)" = 'Amazon Linux AMI' ]]; then
    CENTOS_SIX='6'
fi

buildmodule() {
  setver=$1
  cd /svr-setup
  wget -q -O get-php-ver.sh https://github.com/centminmod/get-php-versions/raw/master/get-php-ver.sh
  chmod +x get-php-ver.sh
  phpversions=$(bash get-php-ver.sh)
  if [ "$setver" ]; then
    phpversions="$setver"
    echo "phpversions=$phpversions"
  fi
  echo "$phpversions"
  echo "downloading php versions..."
  for phpver in $phpversions; do
    PHPMVER=$(echo "$phpver" | cut -d . -f1,2)  
    # for PHP versions lower than 7.1 switch back to system libicu versions for compatibility
    if [[ "$PHPMVER" = 5.[23456] ]]; then
      NEWLIBICU='n'
      echo "NEWLIBICU=$NEWLIBICU"
    fi
    if [[ "$PHPMVER" = '7.0' ]]; then
      NEWLIBICU='n'
      echo "NEWLIBICU=$NEWLIBICU"
    fi
    if [[ "$PHPMVER" = 7.[1234] ]]; then
      NEWLIBICU='y'
      echo "NEWLIBICU=$NEWLIBICU"
    fi
    if [[ ! -f /usr/bin/icu-config ]]; then
      if [[ "$NEWLIBICU" = [yY] && "$CENTOS_SEVEN" = '7' && -f /etc/yum.repos.d/remi.repo && -f /etc/yum.repos.d/rpmforge.repo ]]; then
        yum -q -y install libicu62 libicu62-devel --enablerepo=remi --disablerepo=rpmforge,epel
      elif [[ "$NEWLIBICU" = [yY] && "$CENTOS_SEVEN" = '7' && -f /etc/yum.repos.d/remi.repo && ! -f /etc/yum.repos.d/rpmforge.repo ]]; then
        yum -q -y install libicu62 libicu62-devel --enablerepo=remi --disablerepo=epel
      elif [[ "$CENTOS_SIX" = '6' && -f /etc/yum.repos.d/remi.repo && -f /etc/yum.repos.d/rpmforge.repo ]]; then
        yum -q -y install libicu-last libicu-last-devel --enablerepo=remi --disablerepo=rpmforge,epel
      elif [[ "$CENTOS_SIX" = '6' && -f /etc/yum.repos.d/remi.repo && ! -f /etc/yum.repos.d/rpmforge.repo ]]; then
        yum -q -y install libicu-last libicu-last-devel --enablerepo=remi --disablerepo=epel
      elif [ -f /etc/yum.repos.d/rpmforge.repo ]; then
        yum -q -y install libicu libicu-devel --disablerepo=rpmforge,epel
      else
        yum -q -y install libicu libicu-devel --disablerepo=epel
      fi
    fi
    if [[ "$NEWLIBICU" = [yY] && "$CENTOS_SEVEN" = '7' && -f /etc/yum.repos.d/remi.repo && -f /usr/bin/icu-config && "$(/usr/bin/icu-config --version| cut -d . -f1)" -lt '62' ]]; then
      # update centos 7 libicu 50.1 version to remi yum repo provided libicu 62.1 version
      yum -y install libicu62 --enablerepo=remi
      yum -y swap libicu-devel libicu62-devel --enablerepo=remi
    fi
    # for PHP versions lower than 7.1 switch back to system libicu versions for compatibility
    if [[ "$NEWLIBICU" = [nN] && "$CENTOS_SEVEN" = '7' && -f /etc/yum.repos.d/remi.repo && -f /usr/bin/icu-config && "$(/usr/bin/icu-config --version| cut -d . -f1)" -gt '50' ]]; then
      # update centos 7 libicu 50.1 version to remi yum repo provided libicu 62.1 version
      if [ "$(rpm -ql libicu62)" ]; then
        yum -y remove libicu62 --enablerepo=remi
        if [ -f /etc/yum.repos.d/rpmforge.repo ]; then
          yum -y install libicu-devel --disablerepo=rpmforge,epel
        else
          yum -y install libicu-devel --disablerepo=epel
        fi
      fi
      if [ "$(rpm -ql libicu62-devel)" ]; then
        yum -y swap libicu62-devel libicu-devel --enablerepo=remi
      fi
    fi
  
    cd /svr-setup
    download="https://php.net/get/php-$phpver.tar.gz/from/this/mirror"
    echo "-------------------------------------------------"
    echo "download PHP $phpver"
    echo "-------------------------------------------------"
    echo "wget -q -O php-$phpver.tar.gz $download"
    wget -q -O "php-$phpver.tar.gz" "$download"
    echo "ls -lah | grep php-$phpver.tar.gz"
    ls -lah | grep "php-$phpver.tar.gz"
    tar xzf "php-$phpver.tar.gz"
    cd "/svr-setup/php-$phpver"
    #autoreconf -f -i
    ./buildconf --force
    mkdir -p fpm-build
    cd fpm-build
    if [[ "$SILENT" = [yY] ]]; then
      make clean >/dev/null 2>&1
    else
      make clean
    fi
    ../configure --enable-fpm --enable-opcache --enable-intl --enable-pcntl --with-mcrypt --with-snmp --enable-embed=shared --with-mhash --with-zlib --with-gettext --enable-exif --enable-zip --with-bz2 --enable-soap --enable-sockets --enable-sysvmsg --enable-sysvsem --enable-sysvshm --enable-shmop --with-pear --enable-mbstring --with-openssl --with-mysql=mysqlnd --with-libdir=lib64 --with-mysqli=mysqlnd --with-mysql-sock=/var/lib/mysql/mysql.sock --with-curl --with-gd --with-xmlrpc --enable-bcmath --enable-calendar --enable-ftp --enable-gd-native-ttf --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr --with-xpm-dir=/usr --with-webp-dir=/usr --with-t1lib=/usr --enable-pdo --with-pdo-sqlite --with-pdo-mysql=mysqlnd --enable-inline-optimization --with-imap --with-imap-ssl --with-kerberos --with-readline --with-libedit --with-gmp --with-pspell --with-tidy --with-enchant --with-fpm-user=nginx --with-fpm-group=nginx --with-ldap --with-ldap-sasl --with-config-file-scan-dir=/etc/centminmod/php.d --with-xsl
    echo "php-$phpver make"
    if [[ "$SILENT" = [yY] ]]; then
      echo "make -j$(nproc) >/dev/null 2>&1"
      make -j$(nproc) >/dev/null 2>&1
    else
      echo "make -j$(nproc)"
      make -j$(nproc)
    fi
    err=$?
    if [[ "$err" -ne '0' ]]; then
      echo "error: make failed"
    else
      echo "success: make ok"
      echo
      bash "/svr-setup/php-$phpver/fpm-build/scripts/php-config"
      echo
    fi
    echo "-------------------------------------------------"
    echo "build fileinfo extension"
    echo "-------------------------------------------------"
    cd "/svr-setup/php-$phpver/ext/fileinfo"
    if [[ "$SILENT" = [yY] ]]; then
      make clean >/dev/null 2>&1
    else
      make clean
    fi
    # bash "/svr-setup/php-$phpver/fpm-build/scripts/phpize"
    chmod +x "/svr-setup/php-${phpver}/fpm-build/scripts/php-config"
    phpize
    if [[ "$SILENT" = [yY] ]]; then
      ./configure -q --with-php-config="/svr-setup/php-${phpver}/fpm-build/scripts/php-config"
    else
      ./configure --with-php-config="/svr-setup/php-${phpver}/fpm-build/scripts/php-config"
    fi
    echo "php-$phpver make fileinfo"
    if [[ "$SILENT" = [yY] ]]; then
      echo "make -j$(nproc) >/dev/null 2>&1"
      make -j$(nproc) >/dev/null 2>&1
    else
      echo "make -j$(nproc)"
      make -j$(nproc)
    fi
    err=$?
    if [[ "$err" -ne '0' ]]; then
      echo "error: make failed"
    else
      echo "success: make ok"
      echo
      cp -a "/svr-setup/php-$phpver/ext/fileinfo/modules/fileinfo.so" "/svr-setup/php-$phpver/ext/fileinfo/modules/fileinfo.so-b4strip"
      strip -s "/svr-setup/php-$phpver/ext/fileinfo/modules/fileinfo.so"
      echo
    fi
    echo "-------------------------------------------------"
    echo "fileinfo extension built"
    echo "-------------------------------------------------"
    echo
    echo "fileinfo.so belongs in $(bash /svr-setup/php-$phpver/fpm-build/scripts/php-config --extension-dir)"
    echo
    echo "ls -lah /svr-setup/php-$phpver/ext/fileinfo/modules"
    ls -lah "/svr-setup/php-$phpver/ext/fileinfo/modules"
    echo
  done
}

buildmodule $1