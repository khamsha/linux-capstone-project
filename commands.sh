#router configuration
#echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
#sudo iptables -I INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
#sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
#sudo iptables -A INPUT -i lo -j ACCEPT
#sudo iptables -P INPUT DROP
sudo iptables -A PREROUTING -t nat -p tcp -d 10.129.0.6 --dport 80 -j DNAT --to-destination 10.129.0.32:443
sudo iptables -A PREROUTING -t nat -p tcp -d 10.129.0.6 --dport 443 -j DNAT --to-destination 10.129.0.32:443
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
#sudo iptables -t filter -A FORWARD -d 10.129.0.32 -p tcp --dport 80 -j ACCEPT
#sudo iptables -t filter -A FORWARD -s 10.129.0.32 -p tcp --dport 80 -j ACCEPT
#sudo iptables -t filter -A FORWARD -d 10.129.0.32 -p tcp --dport 443 -j ACCEPT
#sudo iptables -t filter -A FORWARD -s 10.129.0.32 -p tcp --dport 443 -j ACCEPT
#sudo iptables -t filter -A FORWARD -d 10.129.0.32 -p tcp --dport 53 -j ACCEPT
#sudo iptables -t filter -A FORWARD -s 10.129.0.32 -p tcp --dport 53 -j ACCEPT
#sudo iptables -t filter -A FORWARD -d 10.129.0.32 -p udp --dport 53 -j ACCEPT
#sudo iptables -t filter -A FORWARD -s 10.129.0.32 -p udp --dport 53 -j ACCEPT
#sudo iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
#sudo iptables -t filter -P FORWARD DROP
iptables-save > /etc/iptables.rules
echo "iptables-restore < /etc/iptables.rules" | sudo tee -a /etc/rc.local
___________________________
#nfs host configuration
sudo -i
yum install epel-release -y
yum install certbot -y
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
bash
#source "/root/.bashrc"
yc config profile create dns-profile
#yc config set service-account-key key.json
yc config set cloud-id b1g7io5abmkqch37r715
yc config set folder-id b1gulec3r5ftba4hjefj #to change
DOMAIN="tech.familygram.ru" #to change
EMAIL="akhamatshin@gmail.com"

touch authenticate.sh
cat <<-EOF > authenticate.sh
#!/bin/bash

yc dns zone add-records --name familygram --record "_acme-challenge.tech 300 TXT \$CERTBOT_VALIDATION"

# Sleep to make sure the change has time to propagate over to DNS
sleep 25
EOF

chmod +x authenticate.sh
certbot certonly --manual -n --preferred-challenges=dns --agree-tos --manual-auth-hook ./authenticate.sh --email "$EMAIL" --domain "$DOMAIN"

certbot certonly --manual --preferred-challenges=dns --email "$EMAIL" --domain "$DOMAIN"

___________________________
#nginx host configuration
sudo yum install epel-release -y
sudo yum install nginx -y
sudo yum install firewalld -y
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
sudo systemctl start nginx
sudo systemctl enable nginx