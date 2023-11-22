#router configuration (10.129.0.10)

#Включаем ip forwarding
#echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
#echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
#sudo sysctl -p
sudo sysctl -w net.ipv4.ip_forward=1

#Разрешаем доступ на хост только по 22 порту
#sudo iptables -I INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
#sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
#sudo iptables -A INPUT -i lo -j ACCEPT
#sudo iptables -P INPUT DROP

#Настраиваем NAT и Forwarding
sudo iptables -A PREROUTING -t nat -p tcp -d 10.129.0.10 --dport 80 -j DNAT --to-destination 10.129.0.30:443
sudo iptables -A PREROUTING -t nat -p tcp -d 10.129.0.10 --dport 443 -j DNAT --to-destination 10.129.0.30:443
sudo iptables -A PREROUTING -t nat -p tcp -d 10.129.0.10 --dport 8080 -j DNAT --to-destination 10.129.0.30:8080 #temp for test
sudo iptables -A POSTROUTING -t nat -o eth0 -j MASQUERADE
#sudo iptables -t filter -A FORWARD -d 10.129.0.30 -p tcp --dport 80 -j ACCEPT
#sudo iptables -t filter -A FORWARD -s 10.129.0.30 -p tcp --dport 80 -j ACCEPT
#sudo iptables -t filter -A FORWARD -d 10.129.0.30 -p tcp --dport 443 -j ACCEPT
#sudo iptables -t filter -A FORWARD -s 10.129.0.30 -p tcp --dport 443 -j ACCEPT
#sudo iptables -t filter -A FORWARD -d 10.129.0.30 -p tcp --dport 53 -j ACCEPT
#sudo iptables -t filter -A FORWARD -s 10.129.0.30 -p tcp --dport 53 -j ACCEPT
#sudo iptables -t filter -A FORWARD -d 10.129.0.30 -p udp --dport 53 -j ACCEPT
#sudo iptables -t filter -A FORWARD -s 10.129.0.30 -p udp --dport 53 -j ACCEPT
#sudo iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
#sudo iptables -t filter -P FORWARD DROP

#Сохраняем правила iptables в файл и готовим его к старту при перезагрузке
sudo iptables-save | sudo tee /etc/iptables.rules
echo "iptables-restore < /etc/iptables.rules" | sudo tee -a /etc/rc.local

#__________________________________________________________________________

#nfs host configuration (10.129.0.20) with sa-otus-dns

sudo yum update -y
sudo yum install epel-release -y
sudo yum install certbot nfs-utils git -y

#Настраиваем NFS сервер
sudo mkdir -p /shared/templates
sudo systemctl enable nfs --now

cat << EOF | sudo tee /etc/exports
/shared/templates *(rw,sync,root_squash,no_subtree_check)
/etc/letsencrypt/live/ *(rw,sync,no_subtree_check,nohide)
EOF

sudo exportfs -r

#Скачиваем репозиторий и добавляем в NFS
git clone https://github.com/khamsha/linux-capstone-project.git
sudo cp -R ~/linux-capstone-project/* /shared/templates/
sudo chown -R nfsnobody:nfsnobody /shared/templates

#Устанавливаем и настраиваем утилиту yc для автоматизации работы с DNS
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
sudo cp yandex-cloud/bin/yc /bin/yc
sudo yc config profile create dns-profile
#yc config set service-account-key key.json
sudo yc config set cloud-id b1g7io5abmkqch37r715
sudo yc config set folder-id b1gulec3r5ftba4hjefj #to change
DOMAIN="tech.familygram.ru" #to change
EMAIL="akhamatshin@gmail.com"

#Готоваим аутентификационный скрипт, чтобы автоматически пройти проверку от Certbot
touch authenticate.sh
cat <<-EOF > authenticate.sh
#!/bin/bash

yc dns zone add-records --name familygram --record "_acme-challenge.tech 300 TXT \$CERTBOT_VALIDATION"

# Sleep to make sure the change has time to propagate over to DNS
sleep 25
EOF

chmod +x authenticate.sh

#Запускаем certbot для автоматического выпуска сертификатов
sudo certbot certonly --manual -n --preferred-challenges=dns --agree-tos --manual-auth-hook ./authenticate.sh --email "$EMAIL" --domain "$DOMAIN"

#____________________________________________________________________________________________________

#app host configuration (10.128.0.30, 10.129.0.30, 10.130.0.30) -> use ubuntu with nginx and keycloak
sudo apt update -y
sudo apt install nginx openjdk-17-jdk nfs-common -y

#Настраиваем NFS клиент
sudo mkdir /mnt/templates
sudo mount -t nfs 10.129.0.20:/shared/templates /mnt/templates
sudo mkdir /mnt/certificates
sudo mount -t nfs 10.129.0.20:/etc/letsencrypt/live /mnt/certificates

#Устанавливаем Keycloak
wget https://github.com/keycloak/keycloak/releases/download/22.0.5/keycloak-22.0.5.tar.gz
tar -xzf keycloak-22.0.5.tar.gz
sudo mv keycloak-22.0.5 /opt/keycloak
sudo groupadd keycloak
sudo useradd -g keycloak --system --shell /sbin/nologin keycloak
sudo chown -R keycloak:keycloak /opt/keycloak
sudo chmod o+x /opt/keycloak/bin/

#Настраиваем systemd сервис для Keycloak
sudo cp /mnt/templates/keycloak.service /etc/systemd/system/keycloak.service
sudo systemctl daemon-reload
sudo systemctl enable keycloak
sudo systemctl start keycloak

#Настраиваем nginx
sudo cp /mnt/templates/nginx.conf /etc/nginx/sites-available/keycloak
sudo ln -s /etc/nginx/sites-available/keycloak /etc/nginx/sites-enabled/
sudo systemctl restart nginx