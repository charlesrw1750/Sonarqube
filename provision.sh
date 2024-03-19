#!/bin/bash
 
# Script para baixar e instalar o Docker
    # Instala o Docker
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo sysctl -w vm.max_map_count=524288
    sudo sysctl -w fs.file-max=131072
   
# criação da rede
 
docker network create sonar_network
 
# instalando postgree
 
docker run --name postgres -e POSTGRES_PASSWORD=sonar -e POSTGRES_USER=sonar -e POSTGRES_DB=sonar -v /var/lib/postgresql/data -p 5432:5432 --network sonar_network -d postgres
 
# Baixa e instala o SonarQube
 
docker run -d --name sonarqube -p 9000:9000 -e sonar.jdbc.username=sonar -e sonar.jdbc.password=sonar -e sonar.jdbc.url=jdbc:postgresql://postgres/sonarqube -v /opt/sonarqube/data -v /opt/sonarqube/logs -v /opt/sonarqube/extensions --network sonar_network -d sonarqube
 

 #