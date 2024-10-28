#-------------------------------Creating VPC------------------------------------------------------------
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

   tags = {
    Name = "MYSTACKVPC"
  }
}



#-------------------------------Creating private subnet to host clixx  -------------------------------------

resource "aws_subnet" "privatesubnetclixx1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "privatesubnet-clixx"
  }
}



#-----------------------------Creating private subnet2 to host clixx --------------------------------------

resource "aws_subnet" "privatesubnetclixx2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.12.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "privatesubnet-clixx2"
  }
}


#------------------------------Creating public subnet for load balancer ------------------------------------

resource "aws_subnet" "publicsubnet1loadbalancer" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/23"
  availability_zone = "us-east-1a"
  tags = {
    Name = "publicsubnet_loadbalancer1"
  }
}




#-----------------------------Creating public subnet 2 for load Balancer ------------------------------------

resource "aws_subnet" "publicsubnet2loadbalancer" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.4.0/23"
  availability_zone = "us-east-1b"
  tags = {
    Name = "publicsubnet_loadbalancer2"
  }
}



#----------------------------Creating private subnet for RDS Database ----------------------------------------
resource "aws_subnet" "privatesubnetrds1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.8.0/22"
  availability_zone = "us-east-1a"
  tags = {
    Name = "privateclixx_rds1"
  }
}

#---------------------------Creating privatesubnet 2 for rds database ----------------------------------------
resource "aws_subnet" "privatesubnetrds2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.16.0/22"
  availability_zone = "us-east-1b"
  tags = {
    Name = "privateclixx_rds2"
  }
}

#------------------------------Creating private subnet for oracle database 1 -------------------------------
resource "aws_subnet" "privatesubnetoracleDB1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.20.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "privateoracle_db1"
  }
}


#--------------------------Creating private subnet for oracle database 2--------------------------------------
resource "aws_subnet" "privatesubnetoracleDB2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.21.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "privateoracle_db2"
  }
}


#-----------------------------creating private subnet for java application databse 1 ----------------------------------
resource "aws_subnet" "privatesubnetjavaDB1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.22.0/26"
  availability_zone = "us-east-1a"
  tags = {
    Name = "privatejava_rds1"
  }
}


#-----------------------------Creating private subnet for java applaication database 2---------------------------------
resource "aws_subnet" "privatesubnetjavaDB2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.23.0/26"
  availability_zone = "us-east-1b"
  tags = {
    Name = "privatejava_rds2"
  }
}


#----------------------------Creating private subnet for java server 1------------------------------------------------
resource "aws_subnet" "privatesubnetjavaserver1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.24.0/26"
  availability_zone = "us-east-1a"
  tags = {
    Name = "privatjavaserver1"
  }
}

#---------------------------Creating private subnet for java server 2----------------------------------------------
resource "aws_subnet" "privatesubnetjavaserver2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.25.0/26"
  availability_zone = "us-east-1b"
  tags = {
    Name = "privatjavaserver2"
  }
}

#---------------------------Creating internet gateway -----------------------------------------------------------
resource "aws_internet_gateway" "internetgateway" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "internet_gatewayclixx"
  }
}


#------------------------- Fetching Elastic IP information to attach to NAT GATEWAY -----------------------------------------
data "aws_eips" "example" {
  filter {
    name   = "tag:Name"
    values = ["STACKEIP-CLIXX"]
  }
}



output "EIP" {
  value = data.aws_eips.example.allocation_ids
}


#-------------------------Creating NAT GATEWAY in public subnet ---------------------------------------------------------
resource "aws_nat_gateway" "NATGATE" {
  allocation_id = data.aws_eips.example.allocation_ids[0]
  subnet_id     = aws_subnet.publicsubnet1loadbalancer.id

  tags = {
    Name = "STACKNATGATEWAY"
  }
  depends_on = [aws_internet_gateway.internetgateway]
}



#----------------------------Creating route table for public subnets ----------------------------------------------
resource "aws_route_table" "pubroutetable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetgateway.id
  }

 

  tags = {
    Name = "Publicroutetable"
  }
}

output "routetab" {
  value = aws_route_table.pubroutetable.id
}


#-------------------------------Creating private route table for private subnets --------------------------------
resource "aws_route_table" "privroutetable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NATGATE.id
  }

  tags = {
    Name = "Privateroutetable"
  }
}

#-------------------------------Associating Public route table to public subnet1-----------------------------------

resource "aws_route_table_association" "ass1" {
  subnet_id      = aws_subnet.publicsubnet1loadbalancer.id
  route_table_id = aws_route_table.pubroutetable.id
}

#------------------------------Associating Public route table to public subnet 2 ------------------------------------
resource "aws_route_table_association" "ass2" {
  subnet_id      = aws_subnet.publicsubnet2loadbalancer.id
  route_table_id = aws_route_table.pubroutetable.id
}

#------------------------------Associating Private route table to private subnet 1-----------------------------
resource "aws_route_table_association" "ass3" {
  subnet_id      = aws_subnet.privatesubnetclixx1.id
  route_table_id = aws_route_table.privroutetable.id
}

#------------------------------Associating Private route table to private subnet 2-----------------------------
resource "aws_route_table_association" "ass4" {
  subnet_id      = aws_subnet.privatesubnetclixx2.id
  route_table_id = aws_route_table.privroutetable.id
}

#------------------------------Associating Private route table to private subnet 3-----------------------------
resource "aws_route_table_association" "ass5" {
  subnet_id      = aws_subnet.privatesubnetrds1.id
  route_table_id = aws_route_table.privroutetable.id
}


#------------------------------Associating Private route table to private subnet 4-----------------------------
resource "aws_route_table_association" "ass6" {
  subnet_id      = aws_subnet.privatesubnetrds2.id
  route_table_id = aws_route_table.privroutetable.id
}


#----------------------------Associating Private route tabel to private subnet 5---------------------------
resource "aws_route_table_association" "ass7" {
  subnet_id      = aws_subnet.privatesubnetoracleDB1.id
  route_table_id = aws_route_table.privroutetable.id
}

#-----------------------------Associating Private route table to private subnet 6---------------------------
resource "aws_route_table_association" "ass8" {
  subnet_id      = aws_subnet.privatesubnetoracleDB2.id
  route_table_id = aws_route_table.privroutetable.id
}

#-----------------------------Associating Private route table to private subnet 6---------------------------
resource "aws_route_table_association" "ass9" {
  subnet_id      = aws_subnet.privatesubnetjavaDB1.id
  route_table_id = aws_route_table.privroutetable.id
}

#-----------------------------Associating Private route table to private subnet 7------------------------
resource "aws_route_table_association" "ass10" {
  subnet_id      = aws_subnet.privatesubnetjavaDB2.id
  route_table_id = aws_route_table.privroutetable.id
}

#---------------------------Associating Private route table to private subnet 8---------------------------
resource "aws_route_table_association" "ass11" {
  subnet_id      = aws_subnet.privatesubnetjavaserver1.id
  route_table_id = aws_route_table.privroutetable.id
}

#---------------------------Associating Private route table to private subnet 9---------------------------
resource "aws_route_table_association" "ass12" {
  subnet_id      = aws_subnet.privatesubnetjavaserver2.id
  route_table_id = aws_route_table.privroutetable.id
}


#--------------------------Creating security group for load Balancer -------------------------------------
resource "aws_security_group" "loadBalancer-sg" {
  vpc_id     = aws_vpc.myvpc.id
  name        = "loadbalancer_Securitygroup"
  description = "Load balancer Security Group"
}

output "loadbalancerid" {
  value = aws_security_group.loadBalancer-sg.id
}


#----------------------------Creating Security group for RDS AND EFS -----------------------------------
resource "aws_security_group" "RDSEFS-sg" {
  vpc_id     = aws_vpc.myvpc.id
  name        = "RDS-AND-EFS_Securitygroup"
  description = "RDS and EFS Security Group"
}

output "RDSEFSid" {
  value = aws_security_group.RDSEFS-sg.id
}

#------------------------Adding Rules to Load Balancer Security Group -------------------------------------
resource "aws_security_group_rule" "httpslb" {
  security_group_id = aws_security_group.loadBalancer-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "httpslb2" {
  security_group_id = aws_security_group.loadBalancer-sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "ssh" {
  security_group_id = aws_security_group.loadBalancer-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "ssh2" {
  security_group_id = aws_security_group.loadBalancer-sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}


#-----------------------------------Creating Security Group for CliXX Application server-----------------------
resource "aws_security_group" "clixxapp-sg" {
  vpc_id     = aws_vpc.myvpc.id
  name        = "clixxapplication_Securitygroup"
  description = "Clixx Instance security group"
}

output "CLIXXSGid" {
  value = aws_security_group.clixxapp-sg.id
}

#-----------------------------Adding ZRules to the Clixx Server security group------------------------------------
resource "aws_security_group_rule" "sshbastion" {
  security_group_id = aws_security_group.clixxapp-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["10.0.2.0/23"]


}

resource "aws_security_group_rule" "sshbastion2" {
  security_group_id = aws_security_group.clixxapp-sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["10.0.2.0/23"]
}


resource "aws_security_group_rule" "mysql" {
  depends_on = [ aws_security_group.clixxapp_sg ]
  security_group_id        = aws_security_group.clixxapp_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.loadBalancer_sg.id  
}


resource "aws_security_group_rule" "mysql2" {
  security_group_id        = aws_security_group.clixxapp_sg.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.loadBalancer_sg.id  
}


resource "aws_security_group_rule" "NFS1" {
  security_group_id        = aws_security_group.clixxapp_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.loadBalancer_sg.id  
}

resource "aws_security_group_rule" "NFS2" {
  security_group_id        = aws_security_group.clixxapp_sg.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.loadBalancer_sg.id  
}


resource "aws_security_group_rule" "NFS3" {
  security_group_id        = aws_security_group.clixxapp_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.RDSEFS.id 
}

resource "aws_security_group_rule" "NFS4" {
  security_group_id        = aws_security_group.clixxapp_sg.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.RDSEFS.id 
}


resource "aws_security_group_rule" "http1" {
  security_group_id        = aws_security_group.clixxapp_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.loadBalancer_sg.id
}


resource "aws_security_group_rule" "http2" {
  security_group_id        = aws_security_group.clixxapp_sg.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = aws_security_group.loadBalancer_sg.id
}


resource "aws_security_group_rule" "msqlrds1" {
  security_group_id        = aws_security_group.RDSEFS.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.clixxapp_sg.id
}

resource "aws_security_group_rule" "msqlrds2" {
  security_group_id        = aws_security_group.RDSEFS.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.clixxapp_sg.id
}

resource "aws_security_group_rule" "NFS22" {
  security_group_id        = aws_security_group.RDSEFS.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.clixxapp_sg.id
}

resource "aws_security_group_rule" "NFS23" {
  security_group_id        = aws_security_group.RDSEFS.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.clixxapp_sg.id
}


resource "aws_security_group_rule" "msql44" {
  security_group_id        = aws_security_group.RDSEFS.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.loadBalancer_sg.id
}


resource "aws_security_group_rule" "msql45" {
  security_group_id        = aws_security_group.RDSEFS.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  source_security_group_id = aws_security_group.loadBalancer_sg.id
}

resource "aws_security_group_rule" "NFS444" {
  security_group_id        = aws_security_group.RDSEFS.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.loadBalancer_sg.id
}

resource "aws_security_group_rule" "NFS445" {
  security_group_id        = aws_security_group.RDSEFS.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 2049
  to_port                  = 2049
  source_security_group_id = aws_security_group.loadBalancer_sg.id
}





#--------------------------Creating Target Group ------------------------------------------
resource "aws_lb_target_group" "instance_target_group" {
  name     = "newclixx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id 

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 120
    interval            = 300
    path                = "/" 
    protocol            = "HTTP"
  }

  tags = {
    Environment = "Development"
  }
}




#--------------------------Creating Load balancer -------------------------------------------------
resource "aws_lb" "test" {
  name               = "autoscalinglb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadBalancer_sg.id]
  subnets            = [aws_subnet.publicsubnet1loadbalancer.id ,aws_subnet.publicsubnet2loadbalancer.id]
  enable_deletion_protection = false
  tags = {
    Environment = "Development"
  }
}


#------------------------------Pulling certificate to attach to load Balancer lsitnenr ----------------------
data "aws_acm_certificate" "amazon_issued" {
  domain      = "*.clixx-azeez.com"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

output "mycerts" {
  value = data.aws_acm_certificate.amazon_issued.arn
}


#------------------------------ attaching target group to load balancer and add certs to listner -------------------
resource "aws_lb_listener" "http" {
  
  load_balancer_arn = aws_lb.test.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn = data.aws_acm_certificate.amazon_issued.arn

  default_action {
    type = "forward"

    
      target_group_arn = aws_lb_target_group.instance_target_group.arn
    
  }
}



#--------------------Declaring variables to be used in the Bootstrap ----------------------------------------------
data "template_file" "bootstrap" {
    template = file(format("%s/scripts/bootstrap.tpl", path.module))
    vars = {
    lb_dns = "https://dev2.clixx-azeez.com" ,
    FILE = aws_efs_file_system.my_efs.id,
    MOUNT_POINT="/var/www/html",
    REGION = "us-east-1"
    condition = "if (isset($$\\_SERVER['HTTP_X_FORWARDED_PROTO']) && $$\\_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {\\n $$\\_SERVER['HTTPS'] = 'on';\\n}"
  }
  
   
}

#-------------------------------Creating Key Pair----------------------------------------------------------------------
resource "aws_key_pair" "Stack_KP" {
  key_name   = "stackkp"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}


#----------------------Creating Launch Template --------------------------------------------------------------------------
resource "aws_launch_template" "my_launch_template" {
  name          = "my-launch-template"
  image_id      = var.ami
  instance_type = var.instance_type

  key_name = aws_key_pair.Stack_KP.key_name
  
  user_data  = base64encode(data.template_file.bootstrap.rendered)


  
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.clixxapp_sg.id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "newinstance"
    }
  }
}


output "launch_template_id" {
  value = aws_launch_template.my_launch_template.id
}
