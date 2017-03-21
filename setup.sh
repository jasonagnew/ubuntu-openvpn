#!/bin/bash
set -e;

echo " "
echo "********************************"
echo "* Welcome to OpenVPN for Ubuntu"
echo "********************************"
echo " "

function set_config () {
  sed -i -e "/$1=/ s@=.*@=$2@" ~/setup.config
}

echo ">>> Installing OpenVPN"
bash << +END
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -qq openvpn easy-rsa curl > /dev/null 2>&1
exit 0
+END

curl -o ~/setup.config https://raw.githubusercontent.com/jasonagnew/ubuntu-openvpn/master/configs/setup.config > /dev/null 2>&1

EMAIL="${6//\@/\\@}" > /dev/null 2>&1

set_config "IP" $1
set_config "KEY_COUNTRY" $2
set_config "KEY_PROVINCE" $3
set_config "KEY_CITY" $4
set_config "KEY_ORG" $5
set_config "KEY_EMAIL" $EMAIL
set_config "KEY_OU" $7

source ~/setup.config

echo ">>> Configure the CA Variables"
bash << +END
make-cadir ~/openvpn-ca > /dev/null 2>&1

source ~/setup.config

sed -i -e "/KEY_COUNTRY=/ s/=.*/=\"$KEY_COUNTRY\"/" ~/openvpn-ca/vars
sed -i -e "/KEY_PROVINCE=/ s/=.*/=\"$KEY_PROVINCE\"/" ~/openvpn-ca/vars
sed -i -e "/KEY_CITY=/ s/=.*/=\"$KEY_CITY\"/" ~/openvpn-ca/vars
sed -i -e "/KEY_ORG=/ s/=.*/=\"$KEY_ORG\"/" ~/openvpn-ca/vars
sed -i -e "/KEY_EMAIL=/ s/=.*/=\"$KEY_EMAIL\"/" ~/openvpn-ca/vars
sed -i -e "/KEY_OU=/ s/=.*/=\"$KEY_OU\"/" ~/openvpn-ca/vars
sed -i -e "/KEY_NAME=/ s/=.*/=\"server\"/" ~/openvpn-ca/vars

exit 0
+END

cd ~/openvpn-ca > /dev/null 2>&1
source ~/openvpn-ca/vars > /dev/null 2>&1

echo ">>> Build the Certificate Authority"
bash << +END
cd ~/openvpn-ca > /dev/null 2>&1
./clean-all 
echo -en "\n\n\n\n\n\n\n\n" | ./build-ca  > /dev/null 2>&1
exit 0
+END

echo ">>> Create the Server Certificate, Key, and Encryption Files"
bash << +END
cd ~/openvpn-ca > /dev/null 2>&1
source vars > /dev/null 2>&1
./build-key-server server > /dev/null 2>&1 << EOF










y
y
EOF
./build-dh > /dev/null 2>&1
openvpn --genkey --secret keys/ta.key > /dev/null 2>&1
exit 0
+END

echo ">>> Generate a Client Certificate and Key Pair"
bash << +END
cd ~/openvpn-ca > /dev/null 2>&1
source vars > /dev/null 2>&1
./build-key client1 > /dev/null 2>&1 << EOF










y
y
EOF
exit 0
+END

echo ">>> Configure the OpenVPN Service"
bash << +END
cd ~/openvpn-ca/keys > /dev/null 2>&1
sudo cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn > /dev/null 2>&1
curl -o /etc/openvpn/server.conf https://raw.githubusercontent.com/jasonagnew/ubuntu-openvpn/master/configs/server/server.conf > /dev/null 2>&1
exit 0
+END

echo ">>> Adjust the Server Networking Configuration"
bash << +END
sed -i '/net.ipv4.ip_forward=1/s/^#//g' /etc/sysctl.conf
sudo sysctl -p > /dev/null 2>&1
exit 0
+END


echo ">>> Create Client Configuration Infrastructure"
bash << +END
source ~/setup.config

mkdir -p ~/client-configs/files > /dev/null 2>&1
chmod 700 ~/client-configs/files > /dev/null 2>&1
curl -o ~/client-configs/base.conf https://raw.githubusercontent.com/jasonagnew/ubuntu-openvpn/master/configs/client/base.conf > /dev/null 2>&1
sed -i -e "s/my-server-1/$IP/g" ~/client-configs/base.conf 
curl -o ~/client-configs/make.sh https://raw.githubusercontent.com/jasonagnew/ubuntu-openvpn/master/configs/client/make.sh > /dev/null 2>&1
chmod 700 ~/client-configs/make.sh > /dev/null 2>&1
exit 0
+END

#Fail2Ban
echo ">>> Installing Fail2Ban"
bash << +END
sudo apt-get -qq install fail2ban > /dev/null 2>&1

touch /etc/fail2ban/jail.local > /dev/null 2>&1
cat >> /etc/fail2ban/jail.local <<EOF
[ssh]
port=22
EOF

sudo service fail2ban restart > /dev/null 2>&1
exit 0
+END

echo ">>> Installing UFW"
bash << +END
sudo apt-get -qq install ufw > /dev/null 2>&1
sudo ufw default deny incoming > /dev/null 2>&1
sudo ufw default allow outgoing > /dev/null 2>&1
sudo ufw allow 22 > /dev/null 2>&1
sudo ufw allow 80 > /dev/null 2>&1
sudo ufw allow 443 > /dev/null 2>&1
sudo ufw allow 1194/udp > /dev/null 2>&1
sudo ufw allow OpenSSH > /dev/null 2>&1

sed -i -e "/DEFAULT_FORWARD_POLICY=/ s/=.*/=ACCEPT/" /etc/default/ufw
sed -i "1s/^/*nat\n:POSTROUTING ACCEPT [0:0]\n-A POSTROUTING -s 10\.8\.0\.0\/8 -o eth0 -j MASQUERADE\nCOMMIT\n /" /etc/ufw/before.rules

echo "Y" | sudo ufw enable > /dev/null 2>&1
exit 0
+END


echo ">>> Start and Enable the OpenVPN Service"
bash << +END
sudo systemctl start openvpn@server > /dev/null 2>&1
sudo systemctl enable openvpn@server > /dev/null 2>&1
exit 0
+END


echo ">>> Generate Client Configurations"
bash << +END
cd ~/client-configs > /dev/null 2>&1
./make.sh client1 > /dev/null 2>&1
exit 0
+END


echo ">>> Build the Certificate Authority"
bash << +END
rm ~/setup.config > /dev/null 2>&1
exit 0
+END

echo " "
echo "********************************"
echo "* Complete: scp root@$IP:~/client-configs/files/client1.ovpn ."
echo "********************************"
echo " "







