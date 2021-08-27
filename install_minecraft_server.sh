#!/bin/bash

# Author: David Fritsch
# Official docs: https://msmhq.com/docs/installation.html

WORKDIR="/srv/storage/disk01/minecraft_servers"
SED_WORKDIR="\/srv\/storage\/disk01\/minecraft_servers"

SERVER_NAME=mcserver01-a
SERVER_USER=minecraft
JARGROUP=mceternal
JAR_FILENAME=forge-1.12.2-14.23.5.2854-universal.jar

MAX_PLAYERS="max-players=6"
SERVER_IP="server-ip=192.168.20.3"
LEVEL_NAME="level-name=MC Eternal 1.4.4 with Mibsi155"
WHITE_LIST="white-list=true"

if [ $(df -h | grep sdb1 | awk '{ print $1  }') == "/dev/sdb1" ]
then
	# Dependencies
	# # Openjdk-8 for old Minecraft version 1.12.2 - eternal based on it
	# # Install software source manager
	apt-get install software-properties-common
	# # Add mirror with openjdk-8-jdk
	apt-add-repository 'deb http://security.debian.org/debian-security stretch/updates main'
	apt-get update
	# # Install openjdk 8
	apt-get install openjdk-8-jdk

	# # Helpertools
	apt-get install screen rsync zip jq
	
	# Download example config file
	wget https://git.io/6eiCSg -O /etc/msm.conf
	
	# Change workdir to your needs
	sed -i "s/\/opt\/msm/${SED_WORKDIR}/g" /etc/msm.conf
	
	# Create Workdir for all Minecraft server stuff
	if [ $(df -h | grep sdb1 | awk '{ print $6  }') == "/srv/storage/disk01" ]
	then
		mkdir -p ${WORKDIR}
	else
		mkdir -p /srv/storage/minecraft_servers
	fi
	
	# Create Systemuser for Minecraft Servers
	useradd ${SERVER_USER} --home ${WORKDIR}
	chown -R ${SERVER_USER}:${SERVER_USER} ${WORKDIR}/
	chmod -R 775 ${WORKDIR}/
	
	# Store worlds in RAM-disk
	sudo mkdir /dev/shm/msm
	sudo chown -R ${SERVER_USER}:${SERVER_USER} /dev/shm/msm
	sudo chmod -R 775 /dev/shm/msm
	
	# Download the MSM script and place it in /etc/init.d
	wget https://git.io/J1GAxA -O /etc/init.d/msm
	
	#Set script permissions, and integrate script with startup/shutdown
	chmod 755 /etc/init.d/msm
	update-rc.d msm defaults 99 10
	
	# Create a shortcut so we can use just type msm
	ln -s /etc/init.d/msm /usr/local/bin/msm
	
	# Ask MSM to update, getting the latest files
	msm update --noinput
	
	#Setup MSM’s included cron script for scheduled tasks and force cron to load script
	sudo wget https://git.io/pczolg -O /etc/cron.d/msm
	sudo service cron reload
	
	# Create a jar group to manage current and future Minecraft versions
	msm jargroup create minecraft minecraft
	
	# Create a new server, and tell it to use the latest of those Minecraft jars
	msm server create ${SERVER_NAME}
	msm ${SERVER_NAME} jar ${JARGROUP}
	# Set the server jar file
	msm ${SERVER_NAME} jar ${JAR_FILENAME} 
	
	# Replace default settings in server.properties with your values
	sed -i "s/max-players=.*/$MAX_PLAYERS/g" ${WORKDIR}/servers/${SERVER_NAME}/server.properties
	sed -i "s/server-ip=.*/$SERVER_IP/g" ${WORKDIR}/servers/${SERVER_NAME}/server.properties
	sed -i "s/level-name=.*/$LEVEL_NAME/g" ${WORKDIR}/servers/${SERVER_NAME}/server.properties
	sed -i "s/white-list=.*/$WHITE_LIST/g" ${WORKDIR}/servers/${SERVER_NAME}/server.properties
		
else
	echo "Here is no second data disk for Minecraft servers!"
fi