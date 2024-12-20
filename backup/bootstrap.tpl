$5
#!/bin/bash
##Install the needed packages and enable the services(MariaDb, Apache)
sudo yum update -y

#Get Ipaddress
#IP_ADDRESS=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

#Mounting 
sudo yum install -y nfs-utils

#TOKEN=$(curl --request PUT "http://169.254.169.254/latest/api/token" --header "X-aws-ec2-metadata-token-ttl-seconds: 3600")
#REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region --header "X-aws-ec2-metadata-token: $TOKEN")
#MOUNT_POINT="/var/www/html"
sudo mkdir -p ${MOUNT_POINT}
sudo chown ec2-user:ec2-user ${MOUNT_POINT}
echo "${FILE}.efs.${REGION}.amazonaws.com:/ ${MOUNT_POINT} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" | sudo tee -a /etc/fstab
sudo mount -a 

sudo yum install git -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install -y httpd mariadb-server
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl is-enabled httpd
 
##Add ec2-user to Apache group and grant permissions to /var/www
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
find /var/www -type f -exec sudo chmod 0664 {} \;
cd /var/www/html

#Install wordpress and unzip it/copy the sample php conf to wp-config
##sudo wget https://wordpress.org/latest.tar.gz
##sudo tar -xzf latest.tar.gz
##cp wordpress/wp-config-sample.php wordpress/wp-config.php
##start the mariadb and create a database/user and grant priv

if [ -f /var/www/html/wp-config.php ]
then
    echo "wp-config.php already exists"
    
else
    echo "wp-config.php does not exist"
    git clone https://github.com/stackitgit/CliXX_Retail_Repository.git
fi
        


#git clone https://github.com/stackitgit/CliXX_Retail_Repository.git
cp -r CliXX_Retail_Repository/* /var/www/html

## set Wordpress to run in an alternative directory
#sudo mkdir /var/www/html/blog
#sudo cp -r wordpress/* /var/www/html/


## Allow wordpress to use Permalinks
sudo sed -i '151s/None/All/' /etc/httpd/conf/httpd.conf
sudo sed -i 's/wordpress-db.cc5iigzknvxd.us-east-1.rds.amazonaws.com/wordpressdbclixx-ecs.cn2yqqwoac4e.us-east-1.rds.amazonaws.com/' /var/www/html/wp-config.php

if [ $? == 0 ]
then
    echo "sed was done"
else
    echo "sed was not done"
fi



#DNS=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
#echo $DNS
#DNS=${lb_dns}
sleep 600
output_variable=$(mysql -u wordpressuser -p -h wordpressdbclixx-ecs.cn2yqqwoac4e.us-east-1.rds.amazonaws.com -D wordpressdb -pW3lcome123 -sse "select option_value from wp_options where option_value like 'CliXX-APP-%';")
echo $output_variable

if [ output_variable == ${lb_dns} ]
then
    echo "DNS Address in the the table"
else
    echo "DNS Address is not in the table"
    #Logging DB
    mysql -u wordpressuser -p -h wordpressdbclixx-ecs.cn2yqqwoac4e.us-east-1.rds.amazonaws.com -D wordpressdb -pW3lcome123<<EOF
    UPDATE wp_options SET option_value ="${lb_dns}" WHERE option_value LIKE "CliXX-APP-%";
EOF
fi


##Grant file ownership of /var/www & its contents to apache user
sudo chown -R apache /var/www

##Grant group ownership of /var/www & contents to apache group
sudo chgrp -R apache /var/www

##Change directory permissions of /var/www & its subdir to add group write 
sudo chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} \;

##Recursively change file permission of /var/www & subdir to add group write perm
sudo find /var/www -type f -exec sudo chmod 0664 {} \;

##Restart Apache
sudo systemctl restart httpd
sudo service httpd restart

##Enable httpd 
sudo systemctl enable httpd 
sudo /sbin/sysctl -w net.ipv4.tcp_keepalive_time=200 net.ipv4.tcp_keepalive_intvl=200 net.ipv4.tcp_keepalive_probes=5