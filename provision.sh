#!/bin/bash

# Install Prerequisites
yum install -y epel-release unzip vim wget

# Install openJDK

openjdk 11.0.15 2022-04-19 LTS
OpenJDK Runtime Environment 18.9 (build 11.0.15+9-LTS)
OpenJDK 64-Bit Server VM 18.9 (build 11.0.15+9-LTS, mixed mode, sharing)

# Install PostgreSQL 10
rpm -Uvh https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm
yum install -y postgresql10-server postgresql10

# Initialize PGDATA
/usr/pgsql-10/bin/postgresql-10-setup initdb

# Enable MD5-based authentication in pg_hba.conf
echo "host        all        all        127.0.0.1/32        md5" >> /var/lib/pgsql/10/data/pg_hba.conf

# Open TCP port 5432 through Firewall
firewall-cmd --permanent --add-port=5432/tcp
firewall-cmd --reload

# Start and Enable postgres service
systemctl start postgresql-10
systemctl enable postgresql-10
systemctl status postgresql-10

# Create PostgreSQL database for SonarQube
sudo -u postgres psql -c "CREATE DATABASE sonar;"
sudo -u postgres psql -c "CREATE USER sonar WITH ENCRYPTED PASSWORD '<sonar-user-password>';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonar TO sonar;"
sudo -u postgres psql -c "ALTER DATABASE sonar OWNER TO sonar;"

# Download latest SonarQube binaries
wget -O /tmp/sonarqube.zip https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.0.zip

# Extract it to /opt
unzip /tmp/sonarqube.zip -d /opt

# Rename SonarQube directory
mv /opt/sonarqube-8.0 /opt/sonarqube

# Adding a service account for SonarQube
useradd --system --no-create-home sonar

# Provide necessary folder permissions
chown -R sonar:sonar /opt/sonarqube

# Configure environment variables
alternatives --config java
echo 'export JAVA_HOME=$(dirname $(dirname $(readlink $(readlink $(which javac)))))' >> /etc/bashrc
source /etc/bashrc
java -version

# Add properties to sonar.properties
cat <<EOT >> /opt/sonarqube/conf/sonar.properties
# DATABASE
sonar.jdbc.username=sonar
sonar.jdbc.password=<sonar-user-password>
sonar.jdbc.url=jdbc:postgresql://localhost/sonar
sonar.jdbc.maxActive=60
sonar.jdbc.maxIdle=5
sonar.jdbc.minIdle=2
sonar.jdbc.maxWait=5000
sonar.jdbc.minEvictableIdleTimeMillis=600000
sonar.jdbc.timeBetweenEvictionRunsMillis=30000
sonar.jdbc.removeAbandoned=true
sonar.jdbc.removeAbandonedTimeout=60

# WEB SERVER
sonar.web.host=127.0.0.1
sonar.web.port=9000
sonar.web.javaOpts=-server -Xms512m -Xmx512m -XX:+HeapDumpOnOutOfMemoryError
sonar.search.javaOpts=-server -Xms512m -Xmx512m -XX:+HeapDumpOnOutOfMemoryError
sonar.ce.javaOpts=-server -Xms512m -Xmx512m -XX:+HeapDumpOnOutOfMemoryError
EOT

# Create SystemD service file
cat <<EOT >> /etc/systemd/system/sonar.service
[Unit]
Description=SonarQube Server
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
LimitNOFILE=65536
LimitNPROC=4096
User=sonar
Group=sonar
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

# Increase virtual memory for ElasticSearch
echo 'vm.max_map_count = 262144' >> /etc/sysctl.d/00-sysctl.conf
sysctl -p /etc/sysctl.d/00-sysctl.conf

# Start and Enable Sonar service
systemctl daemon-reload
systemctl start sonar.service
systemctl enable sonar.service

# Check whether the Sonar service is running
netstat -tulpn | grep 9000

# Monitor Sonar log files for issues
tail -f /opt/sonarqube/logs/sonar.log
