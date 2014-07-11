#!/bin/bash

# SCRIPT GENERATED BY CHRISTIAN FERNANDEZ A MEMBER OF THE HISPAGATOS LABS
# Contributions by Anthony Cozamanis

# arch linux: get install uuid https://aur.archlinux.org/packages/uuid
# arch linux: get install wmiclient https://aur.archlinux.org/packages/wmi-client/
# arch linux: install libpcap libssh libldap libksba  gpgme glib sqlite3 libxml2 libxslt  libmicrohttpd libxslt

# http://download.opensuse.org/repositories/security:/OpenVAS:/UNSTABLE:/v6/xUbuntu_13.04/amd64/

#    This script has a GPLv3 License
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

DIRECTORY="openvas-setup"
LIBRARIES="openvas-libraries-7.0.2"
SCANNER="openvas-scanner-4.0.1"
GREENBONE="greenbone-security-assistant-5.0.1"
CLI="openvas-cli-1.3.0"


if [ ! -d ~/${DIRECTORY} ]; then
  echo -e "Creating $DIRECTORY directory\n"
  mkdir $DIRECTORY
fi

cd ./$DIRECTORY

echo -e "Installing needed packages\n"
sudo apt-get -y install sudo build-essential make cmake nsis pkg-config nmap libssh-dev libgnutls-dev  libglib2.0-dev libpcap-dev libgpgme11-dev uuid-dev bison libksba-dev rsync sqlite3 libsqlite3-dev wget curl alien fakeroot libmicrohttpd-dev libxml2-dev libxslt1-dev xsltproc

echo -e "Downloading required packages\n"

for i in {1..4}
do

	if [ $i == 1 ]
	then
		echo "$i .............. hello"
		ID=1671
		PACKAGE=$LIBRARIES
	
	elif [ $i == 2 ]
	then
		ID=1640
		PACKAGE=$SCANNER
	
	elif [ $i == 3 ]
	then
		ID=1675
		PACKAGE=$GREENBONE

	elif [ $i == 4 ]
	then
		ID=1633
		PACKAGE=$CLI
	fi

	echo -e "Getting $PACKAGE...\n"
	
	wget http://wald.intevation.org/frs/download.php/$ID/$PACKAGE.tar.gz
	
	echo "exporting PGK_CONFIG_PATH"
	export PKG_CONFIG_PATH=/opt/openvas/lib/pkgconfig
	
	tar -zxvf $PACKAGE.tar.gz
	
	cd ./$PACKAGE
	
	if [  -d "build" ]; then
		echo -e "removing build directory for $PACKAGE\n"
		rm -rf  build
	fi
	
	mkdir build
	
	cd build
	cmake -DCMAKE_INSTALL_PREFIX=/opt/openvas ..
	make
	make doc
	sudo make install
	make rebuild_cache
	
	for x in {1..2}
	do
		cd ..
	done

done

echo "Adding openvas to the enviroment PATH"
export PATH=/opt/openvas/bin:/opt/openvas/sbin:$PATH
sudo sh -c "echo 'export PATH=/opt/openvas/bin:/opt/openvas/sbin:$PATH' >> /etc/bash.bashrc" 

sudo sh -c "echo '/opt/openvas/lib' > /etc/ld.so.conf.d/openvas"
sudo sh -c "echo '/opt/openvas/lib' >> /etc/ld.so.conf"
sudo ldconfig


#configure

echo "CONFIGURE"

echo "sudo openvas-mkcert"
sudo /opt/openvas/sbin/openvas-mkcert

echo "Sync NVT"
sudo -b env  PATH="/opt/openvas/bin:/opt/openvas/sbin:$PATH" /opt/openvas/sbin/openvas-nvt-sync

sleep 10

echo "sudo openvas-mkcert-client -n -i"
sudo -b env  PATH="/opt/openvas/bin:/opt/openvas/sbin:$PATH" /opt/openvas/sbin/openvas-mkcert-client -n -i

echo "Starting the scanner"
sudo -b env  PATH="/opt/openvas/bin:/opt/openvas/sbin:$PATH" /opt/openvas/sbin/openvassd

sleep 10

echo "sudo openvasmd --rebuild"
sudo /opt/openvas/sbin/openvasmd --rebuild

sleep 10

echo "doing the ScapData Sync"
sudo -b env  PATH="/opt/openvas/bin:/opt/openvas/sbin:$PATH" /opt/openvas/sbin/openvas-scapdata-sync

sleep 10

echo "Doing the CertData sync"
sudo -b env  PATH="/opt/openvas/bin:/opt/openvas/sbin:$PATH" /opt/openvas/sbin/openvas-certdata-sync


sleep 10 


if [ !  -f "/opt/openvas/etc/openvas/pwpolicy.conf" ]; then
  echo "creating password policy file, read the doc and edit it as you need"
  sudo touch /opt/openvas/etc/openvas/pwpolicy.conf
fi


echo "Starting openvas manager"
sudo -b env  PATH="/opt/openvas/bin:/opt/openvas/sbin:$PATH" /opt/openvas/sbin/openvasmd

echo "Starting GreenBone security assistant"
sudo -b env  PATH="/opt/openvas/bin:/opt/openvas/sbin:$PATH" /opt/openvas/sbin/gsad

echo "Create config file"
sudo -b env  PATH="/opt/openvas/bin:/opt/openvas/sbin:$PATH" openvassd -s > /opt/openvas/etc/openvas/openvassd.conf


echo "Create your first user"
echo "openvasmd --first-user=myuser"


echo "if any issues download and run with the --v7 flag"
echo "wget --no-check-certificate https://svn.wald.intevation.org/svn/openvas/trunk/tools/openvas-check-setup"
