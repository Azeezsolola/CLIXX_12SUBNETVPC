#!/usr/bin/python

import boto3,botocore,base64,time

AWS_REGION='us-east-1'


sts_client=boto3.client('sts')

#Calling the assume_role function
assumed_role_object=sts_client.assume_role(RoleArn='arn:aws:iam::495599767034:role/Engineer', RoleSessionName='mysession')

credentials=assumed_role_object['Credentials']

print(credentials)





#Creating VPC
VPC=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = VPC.create_vpc(
    CidrBlock='10.0.0.0/16',
    TagSpecifications=[
        {
            'ResourceType': 'vpc',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'STACKVPC'
                }
            ]
        }
    ],
    DryRun=False,
    InstanceTenancy='default',
    AmazonProvidedIpv6CidrBlock=False
)

print(response)
vpcid=response['Vpc']['VpcId']
print(vpcid)


#Enabling VPC DNS Resolution
vpcresolution=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = vpcresolution.modify_vpc_attribute(
    EnableDnsHostnames={
        'Value': True
    },
    VpcId=vpcid,
    
)
print(vpcresolution)

#Enabling DNS support in the VPC
vpcresolution2=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = vpcresolution2.modify_vpc_attribute(
    EnableDnsSupport={
        'Value': True
     },
    VpcId=vpcid
)
    
print(vpcresolution2)




#Creating public subnet 

subnet=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = subnet.create_subnet(
    TagSpecifications=[
        {
            'ResourceType': 'subnet',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'publicsub'
                }
            ]
        }
    ],
    AvailabilityZone='us-east-1a',
    CidrBlock='10.0.0.0/24',
    VpcId=vpcid,
    DryRun=False
)
print(response)
publicsubnetid=response['Subnet']['SubnetId']
print(publicsubnetid)


#Creating private subnet 
subnetpub=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = subnetpub.create_subnet(
    TagSpecifications=[
        {
            'ResourceType': 'subnet',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'privatesub'
                }
            ]
        }
    ],
    AvailabilityZone='us-east-1a',
    CidrBlock='10.0.1.0/24',
    VpcId=vpcid,
    DryRun=False
)
print(response)
privatesubnetid=response['Subnet']['SubnetId']
print(privatesubnetid)


#Create internet Gateway
internetgateway=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response =internetgateway.create_internet_gateway(
    TagSpecifications=[
        {
            'ResourceType': 'internet-gateway',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'publicinternetgateway'
                }
            ]
        }
    ],
    DryRun=False
)

print(response)
intgwid=response['InternetGateway']['InternetGatewayId']
print(intgwid)







#internet gateway attachment to the vpc
internetattach=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = internetattach.attach_internet_gateway(
    DryRun=False,
    InternetGatewayId=intgwid,
    VpcId=vpcid
)
print(response)




#Creating Route table
RT=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = RT.create_route_table(
    TagSpecifications=[
        {
            'ResourceType': 'route-table',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'publicRT'
                }
            ]
        }
    ],
    DryRun=False,
    VpcId=vpcid
)

print(response)
routetableid=response['RouteTable']['RouteTableId']
print(routetableid)


#Putting Entry in the public route table
publicRTENTRY=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = publicRTENTRY.create_route(
    RouteTableId=routetableid,       
    DestinationCidrBlock='0.0.0.0/0',  
    GatewayId=intgwid                   
)
print(response)





#Creating NAT gateway
NAT=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = NAT.create_nat_gateway(
    AllocationId='eipalloc-04292754825061e16',
    DryRun=False,
    SubnetId=publicsubnetid,
    TagSpecifications=[
        {
            'ResourceType': 'natgateway',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'NATGW'
                }
            ]
        }
    ]
    
)
print(response)
natid=response['NatGateway']['NatGatewayId']
print(natid)


time.sleep(120)



#Creating private route table
RT2=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = RT2.create_route_table(
    TagSpecifications=[
        {
            'ResourceType': 'route-table',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'privateRT'
                }
            ]
        }
    ],
    DryRun=False,
    VpcId=vpcid
)
print(response)
privateroutetableid=response['RouteTable']['RouteTableId']
print(privateroutetableid)


#Creating entry in the private route table
privateRTENTRY=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = privateRTENTRY.create_route(
    RouteTableId=privateroutetableid,       
    DestinationCidrBlock='0.0.0.0/0',  
    NatGatewayId=natid                  
)
print(response)


#Associating route table to public subnet  
igwass=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = igwass.associate_route_table(
    #GatewayId=intgwid,
    DryRun=False,
    SubnetId=publicsubnetid,
    RouteTableId=routetableid
)

print(response)



#Associating route tabel with private subnet 
igwass2=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = igwass2.associate_route_table(
    #GatewayId=intgwid,
    DryRun=False,
    SubnetId=privatesubnetid,
    RouteTableId=privateroutetableid
)

print(response)




#Creating security group for instance in the public subnet 
pubsg=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = pubsg.create_security_group(
    Description='public_subnet_SG',
    GroupName='publicsubSG',
    VpcId=vpcid,
    TagSpecifications=[
        {
            'ResourceType': 'security-group',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'pubsubnetSG'
                }
            ]
        }
    ],
    DryRun=False
)
print(response)
pubsgid=response['GroupId']
print(pubsgid)



#Adding Rules to security Group
pubrule1=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)

response=pubrule1.authorize_security_group_ingress(
    GroupId=pubsgid,
    IpPermissions=[
        {
            'IpProtocol': 'tcp',
            'FromPort': 80,
            'ToPort': 80,
            'IpRanges': [{'CidrIp': '0.0.0.0/0'}]  
        }
    ]
)


#Aloowing NFS for ec2 instance as this is necessary for target mount
pubrule7=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)

response=pubrule7.authorize_security_group_ingress(
    GroupId=pubsgid,
    IpPermissions=[
        {
            'IpProtocol': 'tcp',
            'FromPort': 2049,
            'ToPort': 2049,
            'IpRanges': [{'CidrIp': '0.0.0.0/0'}]  
        }
    ]
)

pubrule2=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response=pubrule2.authorize_security_group_ingress(
    GroupId=pubsgid,
    IpPermissions=[
        {
            'IpProtocol': 'tcp',
            'FromPort': 22,
            'ToPort': 22,
            'IpRanges': [{'CidrIp': '0.0.0.0/0'}]  
        }
    ]
)



pubrule3=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)

response=pubrule3.authorize_security_group_ingress(
    GroupId=pubsgid,
    IpPermissions=[
        {
            'IpProtocol': 'tcp',
            'FromPort': 443,
            'ToPort': 443,
            'IpRanges': [{'CidrIp': '0.0.0.0/0'}]  
        }
    ]
)




#Creating security group for private subnet 
privsg=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = privsg.create_security_group(
    Description='private_subnet_SG',
    GroupName='privatesubSG',
    VpcId=vpcid,
    TagSpecifications=[
        {
            'ResourceType': 'security-group',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'privatesubnetSG'
                }
            ]
        }
    ],
    DryRun=False
)
print(response)
privsgid=response['GroupId']
print(privsgid)


#Adding rules to the private security group
privrule1=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response=privrule1.authorize_security_group_ingress(
    GroupId=privsgid,
    IpPermissions=[
        {
            'IpProtocol': 'tcp',
            'FromPort': 3306,
            'ToPort': 3306,
            'IpRanges': [{'CidrIp': '10.0.0.0/24'}]  
        }
    ]
)

privrule2=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response=privrule2.authorize_security_group_ingress(
    GroupId=privsgid,
    IpPermissions=[
        {
            'IpProtocol': 'tcp',
            'FromPort': 2049,
            'ToPort': 2049,
            'IpRanges': [{'CidrIp': '10.0.0.0/24'}]  
        }
    ]
)


privrule3=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response=privrule3.authorize_security_group_ingress(
    GroupId=privsgid,
    IpPermissions=[
        {
            'IpProtocol': 'tcp',
            'FromPort': 2049,
            'ToPort': 2049,
            'IpRanges': [{'CidrIp': '10.0.3.0/24'}]  
        }
    ]
)


#Adding rules to the private security group
privrule1=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response=privrule1.authorize_security_group_ingress(
    GroupId=privsgid,
    IpPermissions=[
        {
            'IpProtocol': 'tcp',
            'FromPort': 3306,
            'ToPort': 3306,
            'IpRanges': [{'CidrIp': '10.0.3.0/24'}]  
        }
    ]
)


#Creating private subnet 2 for RDS
subnetpriv=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = subnetpriv.create_subnet(
    TagSpecifications=[
        {
            'ResourceType': 'subnet',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'privatesub2'
                }
            ]
        }
    ],
    AvailabilityZone='us-east-1b',
    CidrBlock='10.0.2.0/24',
    VpcId=vpcid,
    DryRun=False
)
print(response)
privatesubnetid2=response['Subnet']['SubnetId']
print(privatesubnetid2)




#Associating route tabel with private subnet 
igwass3=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = igwass3.associate_route_table(
    #GatewayId=intgwid,
    DryRun=False,
    SubnetId=privatesubnetid2,
    RouteTableId=privateroutetableid
)

print(response)



#Creating RDS group for RDS DB
rdsdbsub = boto3.client('rds',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = rdsdbsub.create_db_subnet_group(
    DBSubnetGroupName='rdsdbsubgroup',
    DBSubnetGroupDescription='Two private subnets',
    SubnetIds=[privatesubnetid2,privatesubnetid],
    Tags=[
            {
                'Key': 'Name',
                'Value': 'rdsdbsubnetgroup'
            }
            
        ]
)
print(response)




# Create RDS DB
rds_client = boto3.client('rds',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
# Restore DB instance from snapshot
response = rds_client.restore_db_instance_from_db_snapshot(
    DBInstanceIdentifier='wordpressdbclixx-ecs2',
    DBSnapshotIdentifier='arn:aws:rds:us-east-1:577701061234:snapshot:wordpressdbclixx-ecs-snapshot',
    DBInstanceClass='db.m6gd.large',
    DBSubnetGroupName='rdsdbsubgroup',
    MultiAZ=True,
    PubliclyAccessible=True,
    VpcSecurityGroupIds=[privsgid]
    )
print(response)

time.sleep(600)



#Creating public subnet 2 because of the load balancer 

subnet2=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = subnet2.create_subnet(
    TagSpecifications=[
        {
            'ResourceType': 'subnet',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': 'publicsub'
                }
            ]
        }
    ],
    AvailabilityZone='us-east-1b',
    CidrBlock='10.0.3.0/24',
    VpcId=vpcid,
    DryRun=False
)
print(response)
publicsubnetid2=response['Subnet']['SubnetId']
print(publicsubnetid2)




#Associating route table to newly created public subnet  
igwass5=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = igwass5.associate_route_table(
    #GatewayId=intgwid,
    DryRun=False,
    SubnetId=publicsubnetid2,
    RouteTableId=routetableid
)

print(response)



#Creating Load balancer 
elb=boto3.client('elbv2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = elb.create_load_balancer(
    Name='autoscalinglb2-azeez',
    Subnets=[publicsubnetid2,publicsubnetid],
    SecurityGroups=[pubsgid],
    Scheme='internet-facing',
    
    Tags=[
        {
            'Key': 'OwnerEmail',
            'Value': 'azeezsolola14+development@outlook.com'
        },
    ],
    Type='application',
    IpAddressType='ipv4'
    )

print(response)
loadbalancerarn=response["LoadBalancers"][0]["LoadBalancerArn"]
print(loadbalancerarn)
LBDNS=response["LoadBalancers"][0]["DNSName"]
print(LBDNS)

ELBZONEID=response["LoadBalancers"][0]["CanonicalHostedZoneId"]
print(ELBZONEID)

time.sleep(300)



#Creating Target Group
response = elb.create_target_group(
    Name='clixxautoscalingtg2',
    Protocol='HTTP',
    ProtocolVersion='HTTP1',
    Port=80,
    VpcId=vpcid,
    HealthCheckProtocol='HTTP',
    HealthCheckEnabled=True,
    HealthCheckIntervalSeconds=300,
    HealthCheckTimeoutSeconds=120,
    HealthCheckPort='80',
    HealthCheckPath='/',
    HealthyThresholdCount=2,
    UnhealthyThresholdCount=5,
    TargetType='instance',
    Matcher={
        'HttpCode': "200,301"
        
    },
    
    IpAddressType='ipv4'
)

targetgrouparn=response['TargetGroups'][0]['TargetGroupArn']
print(targetgrouparn)


#Creating listner on load balancer and attaching taregt group
elb1 = boto3.client('elbv2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = elb1.create_listener(
    LoadBalancerArn=loadbalancerarn, 
    Port=443,
    Protocol='HTTPS',
    Certificates=[  
        {
            'CertificateArn': 'arn:aws:acm:us-east-1:495599767034:certificate/c4b0e3bc-b06f-42f5-b26b-e631e9720f8a'  
        }
    ],
    DefaultActions=[
        {
            'Type': 'forward',
            'TargetGroupArn': targetgrouparn  
        }
    ]
)
listener_arn = response['Listeners'][0]['ListenerArn']
print(listener_arn)



#tie domain name with lb DNS
route53=boto3.client('route53',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = route53.change_resource_record_sets(
    HostedZoneId='Z0099082ZFVZUBLTJX9D',
    ChangeBatch={
        'Comment': 'update_DNS',
        'Changes': [
            {
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': 'dev.clixx-azeez.com',
                    'Type': 'A',
                    'AliasTarget': {
                            'HostedZoneId': ELBZONEID,  
                            'DNSName': LBDNS,
                            'EvaluateTargetHealth': False
                        }
 
                }
            }
        ]
    }
)

print(response)






efs=boto3.client('efs',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
# Create a file system
response = efs.create_file_system(
    CreationToken='devfs', 
    PerformanceMode='generalPurpose',  
    Encrypted=True,  
    ThroughputMode='elastic',  
    Backup=False,  
    Tags=[
        {
            'Key': 'Name',  
            'Value': 'azeezefs'
        },
    ]
)

print(response)
filesystemid=response["FileSystemId"]
print(filesystemid)

time.sleep(300)


#Attaching Security group to efs 
filesystemid=response["FileSystemId"]
security_group_id=privsgid
subnet_ids = [privatesubnetid2,privatesubnetid]
mounttarget=boto3.client('efs',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
for subnet_id in subnet_ids:
  response=mounttarget.create_mount_target(
        FileSystemId=filesystemid,
        SubnetId=subnet_id,
        SecurityGroups=[privsgid]
    )
  
  
  

    
    



FILE=response["FileSystemId"]
MOUNT_POINT="/var/www/html"
REGION='us-east-1'
LB_NS='https://dev.clixx-azeez.com'


#Creating Launch Template 

AWS_REGION='us-east-1'
USER_DATA = """#!/bin/bash

##Install the needed packages and enable the services(MariaDb, Apache)
sudo yum update -y

#Get Ipaddress
#IP_ADDRESS=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

#Mounting 
sudo yum install -y nfs-utils

#TOKEN=$(curl --request PUT "http://169.254.169.254/latest/api/token" --header "X-aws-ec2-metadata-token-ttl-seconds: 3600")
#REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region --header "X-aws-ec2-metadata-token: $TOKEN")
#MOUNT_POINT="/var/www/html"
sudo mkdir -p {mount_point}
sudo chown ec2-user:ec2-user {mount_point}
echo "{file}.efs.{region}.amazonaws.com:/ {mount_point} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" | sudo tee -a /etc/fstab
sleep 300
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
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {{}} \;
find /var/www -type f -exec sudo chmod 0664 {{}} \;
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
sudo sed -i 's/wordpress-db.cc5iigzknvxd.us-east-1.rds.amazonaws.com/wordpressdbclixx-ecs2.cn2yqqwoac4e.us-east-1.rds.amazonaws.com/' /var/www/html/wp-config.php

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
output_variable=$(mysql -u wordpressuser -p -h wordpressdbclixx-ecs2.cn2yqqwoac4e.us-east-1.rds.amazonaws.com -D wordpressdb -pW3lcome123 -sse "select option_value from wp_options where option_value like 'CliXX-APP-%';")
echo $output_variable

if [ output_variable == {lb_dns} ]
then
    echo "DNS Address in the the table"
else
    echo "DNS Address is not in the table"
    #Logging DB
    mysql -u wordpressuser -p -h wordpressdbclixx-ecs2.cn2yqqwoac4e.us-east-1.rds.amazonaws.com -D wordpressdb -pW3lcome123<<EOF
    UPDATE wp_options SET option_value ="{lb_dns}" WHERE option_value LIKE "CliXX-APP-%";
EOF
fi


##Grant file ownership of /var/www & its contents to apache user
sudo chown -R apache /var/www

##Grant group ownership of /var/www & contents to apache group
sudo chgrp -R apache /var/www

##Change directory permissions of /var/www & its subdir to add group write 
sudo chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {{}} \;

##Recursively change file permission of /var/www & subdir to add group write perm
sudo find /var/www -type f -exec sudo chmod 0664 {{}} \;

##Restart Apache
sudo systemctl restart httpd
sudo service httpd restart

##Enable httpd 
sudo systemctl enable httpd 
sudo /sbin/sysctl -w net.ipv4.tcp_keepalive_time=200 net.ipv4.tcp_keepalive_intvl=200 net.ipv4.tcp_keepalive_probes=5

""".format(file=FILE, region=REGION, mount_point=MOUNT_POINT, lb_dns=LB_NS)


encoded_user_data = base64.b64encode(USER_DATA.encode('utf-8')).decode('utf-8')

ec2=boto3.client('ec2',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response=ec2.create_launch_template(
    DryRun=False,
    LaunchTemplateName='oloyede',
    VersionDescription='webserver1',
    LaunchTemplateData={
        'EbsOptimized': True,     
        'ImageId': 'ami-00f251754ac5da7f0',
        'InstanceType': 't2.micro',  
        'KeyName': 'Azeez10',     
        'UserData': encoded_user_data,
        #'SecurityGroupIds': [pubsgid],
        'NetworkInterfaces': [{
            'AssociatePublicIpAddress': True,  
            'DeviceIndex': 0,
            'SubnetId': publicsubnetid,
            'Groups': [pubsgid] 
        }]
    }
    )

    
print(response)
launchtempid=response["LaunchTemplate"]["LaunchTemplateId"]
print(launchtempid)

launchtempname=response["LaunchTemplate"]["LaunchTemplateName"]
print(launchtempname)




#Creating autoscaling
autoscaling = boto3.client('autoscaling', aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response = autoscaling.create_auto_scaling_group(
    AutoScalingGroupName='my-auto-scaling-group',
    
    LaunchTemplate={
        'LaunchTemplateId': launchtempid
        
       
    },
    
    
    MinSize=1,
    MaxSize=3,
    DesiredCapacity=1,
    DefaultCooldown=300,
 

    TargetGroupARNs=[targetgrouparn],
  
    HealthCheckGracePeriod=300,
   
   
    Tags=[
        {
           
            'Key': 'Name',
            'Value': 'newinstance',
            'PropagateAtLaunch': True
        }
    ],
   
    
   
    DefaultInstanceWarmup=300,
    VPCZoneIdentifier = f"{publicsubnetid},{publicsubnetid2}"

     #VPCZoneIdentifier=[publicsubnetid,publicsubnetid2]

 
)

print(response)




#creating Scale out policy
autoscaling = boto3.client('autoscaling', aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
scale_up_policy = autoscaling.put_scaling_policy(
    AutoScalingGroupName='my-auto-scaling-group',
    PolicyName='ScaleUpPolicy',
    AdjustmentType='ChangeInCapacity',
    ScalingAdjustment=1,  
    Cooldown=30  
)
print(scale_up_policy)



#Creating SCale Down Policy
autoscaling = boto3.client('autoscaling', aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
scale_down_policy = autoscaling.put_scaling_policy(
    AutoScalingGroupName='my-auto-scaling-group',
    PolicyName='ScaleDownPolicy',
    AdjustmentType='ChangeInCapacity',
    ScalingAdjustment=-1,  
    Cooldown=30
)
print(scale_down_policy)





# Scale up alarm
cloudwatch = boto3.client('cloudwatch',aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response=cloudwatch.put_metric_alarm(
    AlarmName='CPUUtilizationHigh',
    MetricName='CPUUtilization',
    Namespace='AWS/EC2',
    Statistic='Average',
    Period=300,
    EvaluationPeriods=1,
    Threshold=50.0,  
    ComparisonOperator='GreaterThanThreshold',
    Dimensions=[
        {
            'Name': 'AutoScalingGroupName',
            'Value': 'my-auto-scaling-group'
        },
    ],
    ActionsEnabled=True,
    AlarmActions=[
        scale_up_policy['PolicyARN']  
    ]
)
print(response)



# Scale down alarm
autoscaling = boto3.client('autoscaling', aws_access_key_id=credentials['AccessKeyId'],aws_secret_access_key=credentials['SecretAccessKey'],aws_session_token=credentials['SessionToken'],region_name=AWS_REGION)
response=cloudwatch.put_metric_alarm(
    AlarmName='CPUUtilizationLow',
    MetricName='CPUUtilization',
    Namespace='AWS/EC2',
    Statistic='Average',
    Period=300,
    EvaluationPeriods=1,
    Threshold=25.0,  # Threshold to trigger scale-down
    ComparisonOperator='LessThanThreshold',
    Dimensions=[
        {
            'Name': 'AutoScalingGroupName',
            'Value': 'my-auto-scaling-group'
        },
    ],
    ActionsEnabled=True,
    AlarmActions=[
        scale_down_policy['PolicyARN']  # ARN of the scale-down policy
    ]
)
print(response)




