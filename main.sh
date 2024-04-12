#!/bin/bash

DELIMITER="----------"
GREEN='\033[0;32m'
NC='\033[0m'
STATE_FILE="./script_state"

source ./config.sh

echo -e "select database engine:\n[1] MySQL\n[2] MariaDB\n[3] PostgreSQL\n"
read user_response

updateState() {
  echo "$1" >> "$STATE_FILE"
}

checkState() {
  [ -f "$STATE_FILE" ] && grep -q "$1" "$STATE_FILE"
  return $?
}

checkStateFile() {
  if [ -f "$STATE_FILE" ];
    then
      echo "previous state found. Do you want to continue from where it left off? [y/n]"
      read answer
      if [[ $answer != "y" ]];
        then
          rm -f "$STATE_FILE"
      fi
  else
    echo "no previous state found, starting fresh"
  fi
}

checkOsDistribution() {
  if ! checkState "checkOsDistribution";
    then  
      echo -e "\n$DELIMITER ${GREEN}RUNNING OS CHECKER${NC} $DELIMITER\n"
      if [[ -f /etc/debian_version ]];
        then
          OSDistributionFamily=DEB
      elif [[ -f /etc/redhat-release ]];
        then
          OSDistributionFamily=RHEL
      else
        echo "Unknown distribution"
      fi
      echo -e "\n$DELIMITER ${GREEN}OS CHECKER COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "checkOsDistribution"
  else
    echo "checkOsDistribution already completed, skipping..."
  fi
}

runUpdate() {
  if ! checkState "runUpdate";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING UPDATE${NC} $DELIMITER\n"
      if [[ $OSDistributionFamily == "DEB" ]];
        then
          apt update
      elif [[ $OSDistributionFamily == "RHEL" ]];
        then
          dnf makecache
      else
        echo "Package manager cache is not updated"
      fi
      echo -e "\n$DELIMITER ${GREEN}UPDATE COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "runUpdate"
  else
    echo "runUpdate already completed, skipping..."
  fi
}

installRequiredSoftware() {
  if ! checkState "installRequiredSoftware";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING REQUIRED SOFTWARE INSTALLATION${NC} $DELIMITER\n"
      if [[ $OSDistributionFamily == "DEB" ]];
        then
          apt install -y wget git
      elif [[ $OSDistributionFamily == "RHEL" ]];
        then
          dnf install -y wget git
      else
        echo "Required software is not installed"
      fi
      echo -e "\n$DELIMITER ${GREEN}REQUIRED SOFTWARE COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "installRequiredSoftware"
  else
    echo "installRequiredSoftware already completed, skipping..."
  fi
}

apache2Installation() {
  if ! checkState "apache2Installation";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING APACHE2 INSTALLATION${NC} $DELIMITER\n"
      if [[ $OSDistributionFamily == "DEB" ]];
        then
          apt install -y apache2
          sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf
          systemctl start apache2
      elif [[ $OSDistributionFamily == "RHEL" ]];
        then
          dnf install -y httpd
          sed -i 's/Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf
          systemctl start httpd
      else
        echo "Apache2 is not installed"
      fi
      echo -e "\n$DELIMITER ${GREEN}APACHE2 INSTALLATION COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "apache2Installation"
  else
    echo "apache2Installation already completed, skipping..."
  fi
}

phpInstallation() {
  if ! checkState "phpInstallation";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING PHP INSTALLATION${NC} $DELIMITER\n"
      if [[ $OSDistributionFamily == "DEB" ]];
        then
          apt install -y php
      elif [[ $OSDistributionFamily == "RHEL" ]];
        then
          dnf install -y php
      else
        echo "PHP is not installed"
      fi
      systemctl start php-fpm
      echo -e "\n$DELIMITER ${GREEN}PHP INSTALLATION COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "phpInstallation"
  else
    echo "phpInstallation already completed, skipping..."
  fi
}

mysqlServerInstallation() {
  if ! checkState "mysqlServerInstallation";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING MYSQL SERVER INSTALLATION${NC} $DELIMITER\n"
      if [[ $OSDistributionFamily == "DEB" ]];
        then
          wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb
          dpkg -i mysql-apt-config_*.deb
          apt update
          apt install -y mysql-server
          apt install -y php-mysql
      elif [[ $OSDistributionFamily == "RHEL" ]];
        then
          rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el9-5.noarch.rpm
          dnf install -y mysql-community-server
          dnf install -y php-mysqli
      else
        echo "MySQL is not installed"
      fi
      systemctl start mysqld
      echo -e "\n$DELIMITER ${GREEN}MYSQL SERVER INSTALLATION COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "mysqlServerInstallation"
  else
    echo "mysqlServerInstallation already completed, skipping..."
  fi
}

mariadbServerInstallation() {
  if ! checkState "mariadbServerInstallation";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING MARIADB SERVER INSTALLATION${NC} $DELIMITER\n"
      if [[ $OSDistributionFamily == "DEB" ]];
        then
          apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
          name_of_distribution=$(lsb_release -cs)
          add-apt-repository "deb [arch=amd64,arm64,ppc64el] https://mirror.mariadb.org/repo/10.5/${name_of_distribution} main"
          apt update
          apt install -y mariadb-server
          apt install -y php-mysql
      elif [[ $OSDistributionFamily == "RHEL" ]];
        then
          rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
          tee /etc/yum.repos.d/MariaDB.repo<<EOF
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/11.4/rhel9-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
          dnf install -y mariadb-server
          dnf install -y php-mysqlnd
      else
        echo "MariaDB is not installed"
      fi
      systemctl start mariadb
      echo -e "\n$DELIMITER ${GREEN}MARIADB SERVER INSTALLATION COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "mariadbServerInstallation"
  else
    echo "mariadbServerInstallation already completed, skipping..."
  fi
}

postgresqlInstallation() {
  if ! checkState "postgresqlInstallation";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING POSTGRESQL INSTALLATION${NC} $DELIMITER\n"
      if [[ $OSDistributionFamily == "DEB" ]];
        then
          wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
          RELEASE=$(lsb_release -cs)
          echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
          apt update
          apt install -y postgresql
          apt install -y php-pgsql
      elif [[ $OSDistributionFamily == "RHEL" ]];
        then
          dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-$(rpm -E %{rhel})-x86_64/pgdg-redhat-repo-latest.noarch.rpm
          dnf -qy module disable postgresql
          dnf install -y postgresql-server
          dnf install -y php-pgsql
          /usr/bin/postgresql-setup initdb
      else
        echo "PostgreSQL is not installed"
      fi
      systemctl start postgresql
      echo -e "\n$DELIMITER ${GREEN}POSTGRESQL INSTALLATION COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "postgresqlInstallation"
  else
    echo "postgresqlInstallation already completed, skipping..."
  fi
}

nginxInstallation() {
  if ! checkState "nginxInstallation";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING NGINX INSTALLATION${NC} $DELIMITER\n"
      if [[ $OSDistributionFamily == "DEB" ]];
        then
          apt install -y nginx
      elif [[ $OSDistributionFamily == "RHEL" ]];
        then
          dnf install -y epel-release
          dnf install -y nginx
      else
        echo "NGINX is not installed"
      fi
      systemctl start nginx
      echo -e "\n$DELIMITER ${GREEN}NGINX INSTALLATION COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "nginxInstallation"
  else
    echo "nginxInstallation already completed, skipping..."
  fi
}

wordpressInstallation() {
  if ! checkState "wordpressInstallation";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING WORDPRESS INSTALLATION${NC} $DELIMITER\n"
      mkdir ./wordpress && cd ./wordpress
      wget https://wordpress.org/latest.tar.gz
      tar -xzvf ./latest.tar.gz
      rm ./latest.tar.gz
      mkdir /var/www/html/wordpress && mv ./wordpress/* /var/www/html/wordpress && chown -R apache:apache /var/www/html/wordpress
      cd .. && rm -r ./wordpress
      echo "<?php phpinfo(); ?>" > /var/www/html/wordpress/test.php
      echo -e "\n$DELIMITER ${GREEN}JOOMLA INSTALLATION COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "wordpressInstallation"
  else
    echo "wordpressInstallation already completed, skipping..."
  fi
}

joomlaInstallation() {
  if ! checkState "joomlaInstallation";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING JOOMLA INSTALLATION${NC} $DELIMITER\n"
      mkdir ./joomla && cd ./joomla
      wget https://downloads.joomla.org/cms/joomla5/5-0-3/Joomla_5-0-3-Stable-Full_Package.tar.gz || { echo "error downloading joomla"; exit 1; }
      tar -xzvf ./Joomla_5-0-3-Stable-Full_Package.tar.gz
      rm ./Joomla_5-0-3-Stable-Full_Package.tar.gz
      mkdir /var/www/html/joomla && mv ./* /var/www/html/joomla && chown -R apache:apache /var/www/html/joomla
      cd .. && rm -r ./joomla
      echo -e "\n$DELIMITER ${GREEN}JOOMLA INSTALLATION COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "joomlaInstallation"
  else
    echo "joomlaInstallation already completed, skipping..."
  fi
}

setWebServerConfigs() {
  if ! checkState "setWebServerConfigs";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING SETUP WEB SERVER CONFIGS${NC} $DELIMITER\n"
      if [[ $OSDistributionFamily == "DEB" ]];
        then
          git clone https://github.com/vishnevayakostochka/configs.git
          cd ./configs/toBash_and_Ansible/
          mv ./wordpress /etc/apache2/sites-available/ && mv ./wordpress.conf /etc/nginx/sites-available/
          mv ./joomla /etc/apache2/sites-available/ && mv ./joomla.conf /etc/nginx/sites-available/
          a2ensite wordpress joomla
          ln -s /etc/nginx/sites-available/wordpress.conf /etc/nginx/sites-enabled/
          ln -s /etc/nginx/sites-available/joomla.conf /etc/nginx/sites-enabled/
          cd .. && rm -r ./configs
          systemctl restart apache2
      elif [[ $OSDistributionFamily == "RHEL" ]];
        then
          git clone https://github.com/vishnevayakostochka/configs.git
          cd ./configs/toBash_and_Ansible/
          mv ./wordpress /etc/httpd/conf.d/ && mv ./wordpress.conf /etc/nginx/conf.d/
          mv ./joomla /etc/httpd/conf.d/ && mv ./joomla.conf /etc/nginx/conf.d/
          cd .. && rm -r ./configs
          systemctl restart httpd
      else
        echo "configs is not setup"
      fi
      echo -e "\n$DELIMITER ${GREEN}SETUP WEB SERVER CONFIGS COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "setWebServerConfigs"
  else
    echo "setWebServerConfigs already completed, skipping..."
  fi
}

disableSELinux() {
  if ! checkState "disableSELinux";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING DISABLING SELINUX${NC} $DELIMITER\n"
      if [[ $OSDistributionFamily == "RHEL" ]];
        then
          setenforce 0
      else
        echo "you don't need to disable selinux"
      fi
      echo -e "\n$DELIMITER ${GREEN}SELINUX DISABLING COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "disableSELinux"
  else
    echo "disableSELinux already completed, skipping..."
  fi
}

restartNginx() {
  if ! checkState "restartNginx";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING NGINX RESTART${NC} $DELIMITER\n"
      if pgrep nginx > /dev/null 2>&1
        then
          systemctl restart nginx
      else
        echo "Nginx doesn't running"
      fi
      echo -e "\n$DELIMITER ${GREEN}NGINX RESTART COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "restartNginx"
  else
    echo "restartNginx already completed, skipping..."
  fi
}

tgSendMessage() {
  if ! checkState "tgSendMessage";
    then
      echo -e "\n$DELIMITER ${GREEN}RUNNING SEND MESSAGE TO TELEGRAM${NC} $DELIMITER\n"
      MESSAGE="the script completed successfully"
      curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT_ID" -d text="$MESSAGE"
      echo -e "\n$DELIMITER ${GREEN}SEND MESSAGE TO TELEGRAM COMPLETED SUCCESSFULLY${NC} $DELIMITER\n"
      updateState "restartNginx"
  else
    echo "tgSendMessage already completed, skipping..."
  fi
}

main() {
  checkStateFile
  checkOsDistribution
  runUpdate
  installRequiredSoftware
  apache2Installation
  phpInstallation
  if [[ $user_response == 1 ]];
    then
      mysqlServerInstallation
  elif [[ $user_response == 2 ]];
    then
      mariadbServerInstallation
  elif [[ $user_response == 3 ]];
    then
      postgresqlInstallation
  else
    exit 1
  fi
  nginxInstallation
  wordpressInstallation
  joomlaInstallation
  setWebServerConfigs
  disableSELinux
  restartNginx
  if [ -f ./config.sh ];
    then
      tgSendMessage
  else
    echo "you don't configure telegram settings"
  fi
}

main