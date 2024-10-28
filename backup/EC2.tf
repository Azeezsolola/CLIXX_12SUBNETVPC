#-------Creating EFS-------------
resource "aws_efs_file_system" "my_efs" {
  creation_token = "my-efs-token"

  tags = {
    Name = "MyEFS"
    Environment = "Development"
  }
}



#------Creating Mount Target--------
resource "aws_efs_mount_target" "my_efs_mount_target" {
  count            = length(var.availability_zone)  
  file_system_id   = aws_efs_file_system.my_efs.id
  subnet_id        = aws_subnet.privatesub[count.index].id  
  security_groups  = [aws_security_group.clixx-sg2.id]
}


#----Creating Load balancer -------
resource "aws_lb" "test" {
  name               = "autoscalinglb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.clixx-sg.id]
  subnets            = [aws_subnet.publicsub[0].id,aws_subnet.publicsub[1].id]
  enable_deletion_protection = false
  tags = {
    Environment = "Development"
  }
}






# Target Group
resource "aws_lb_target_group" "instance_target_group" {
  name     = "autoscalingtg"
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


data "aws_acm_certificate" "amazon_issued" {
  domain      = "*.clixx-azeez.com"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}


output "mycerts" {
  value = data.aws_acm_certificate.amazon_issued.arn
}


# Listener for the Load Balancer
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

data "template_file" "bootstrap" {
    template = file(format("%s/scripts/bootstrap.tpl", path.module))
    vars = {
    lb_dns = "https://dev2.clixx-azeez.com" ,
    FILE = aws_efs_file_system.my_efs.id,
    MOUNT_POINT="/var/www/html",
    REGION = "us-east-1" 
  }
  
   
}



#-------- Create a launch template----------------
resource "aws_launch_template" "my_launch_template" {
  name          = "my-launch-template"
  image_id      = var.ami
  instance_type = var.instance_type

  key_name = aws_key_pair.Stack_KP.key_name
  
  user_data  = base64encode(data.template_file.bootstrap.rendered)


  
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.clixx-sg.id]
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



#----------Create an Auto Scaling group from the launch template-------------------
resource "aws_autoscaling_group" "my_asg" {
  depends_on = [ aws_db_instance.restored_db ]
  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"  
  }

  min_size     = 1
  max_size     = 3
  desired_capacity = 1
  vpc_zone_identifier = [aws_subnet.publicsub[0].id,aws_subnet.publicsub[1].id]

  tag {
    key                 = "Name"
    value               = "MyAutoScalingInstance"
    propagate_at_launch = true
  }

  target_group_arns = [aws_lb_target_group.instance_target_group.arn]
}


output "autoscaling_group_id" {
  value = aws_autoscaling_group.my_asg.id
}

data "aws_route53_zone" "selected" {
  name         = "clixx-azeez.com"
  
}

output "hostedzone" {
  value = data.aws_route53_zone.selected.zone_id

}

resource "aws_route53_record" "my_record" {
  allow_overwrite = true
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "dev2.clixx-azeez.com"
  type    = "CNAME"
  ttl     = 1500
  records = [aws_lb.test.dns_name]
}


#------Creating Security Group-------
resource "aws_security_group" "clixx-sg" {
  vpc_id     = aws_vpc.myvpc.id
  name        = "clixx-WebDMZ"
  description = "clixx Security Group For clixx Instance"
}


#------Adding Rules to public subnet security Group--------
resource "aws_security_group_rule" "ssh" {
  security_group_id = aws_security_group.clixx-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ssh1" {
  security_group_id = aws_security_group.clixx-sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "NFSEC2" {
  security_group_id = aws_security_group.clixx-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "NFSEC23" {
  security_group_id = aws_security_group.clixx-sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "http" {
  security_group_id = aws_security_group.clixx-sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "http2" {
  security_group_id = aws_security_group.clixx-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "https" {
  security_group_id = aws_security_group.clixx-sg.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "https1" {
  security_group_id = aws_security_group.clixx-sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}



#------Creating security group for instsnces in private subnet 
 resource "aws_security_group" "clixx-sg2" {
  vpc_id     = aws_vpc.myvpc.id
  name        = "clixx-DB"
  description = "clixx Security Group For RDSInstance"
}

resource "aws_security_group_rule" "NFS" {
  security_group_id = aws_security_group.clixx-sg2.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_blocks       = ["10.0.2.0/24"]
}

resource "aws_security_group_rule" "NFS40" {
  security_group_id = aws_security_group.clixx-sg2.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_blocks       = ["10.0.3.0/24"]

}

resource "aws_security_group_rule" "NFS42" {
  security_group_id = aws_security_group.clixx-sg2.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_blocks       = ["10.0.2.0/24"]
}


resource "aws_security_group_rule" "NFS2" {
  security_group_id = aws_security_group.clixx-sg2.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_blocks       = ["10.0.3.0/24"]
}


resource "aws_security_group_rule" "mysql3" {
  security_group_id = aws_security_group.clixx-sg2.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_blocks       = ["10.0.2.0/24"]
}

resource "aws_security_group_rule" "mysql5" {
  security_group_id = aws_security_group.clixx-sg2.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_blocks       = ["10.0.3.0/24"]
}

resource "aws_security_group_rule" "mysql4" {
  security_group_id = aws_security_group.clixx-sg2.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_blocks       = ["10.0.2.0/24"]

}

resource "aws_security_group_rule" "mysql7" {
  security_group_id = aws_security_group.clixx-sg2.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_blocks       = ["10.0.3.0/24"]

}




#-----Create the DB Subnet Group using the retrieved subnet IDs-------------
resource "aws_db_subnet_group" "groupdb" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.privatesub[0].id,aws_subnet.privatesub[1].id]

  tags = {
    Name = "My_DB_Subnet_Group"
  }
}



#------Restoring DB---------
resource "aws_db_instance" "restored_db" {
  identifier          = "wordpressdbclixx-ecs"
  snapshot_identifier = "arn:aws:rds:us-east-1:577701061234:snapshot:wordpressdbclixx-ecs-snapshot"  
  instance_class      = "db.m6gd.large"        
  allocated_storage    = 20                     
  engine             = "mysql"                
  username           = "wordpressuser"
  password           = "W3lcome123"         
  db_subnet_group_name = aws_db_subnet_group.groupdb.name  
  vpc_security_group_ids = [aws_security_group.clixx-sg2.id] 
  skip_final_snapshot     = true
  publicly_accessible  = true
  
  tags = {
    Name = "wordpressdb"
  }
}


#-----key pair ------
resource "aws_key_pair" "Stack_KP" {
  key_name   = "stackkp"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}



#Creating VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

   tags = {
    Name = "STACKVPC"
  }
}


#---------Creating Private Subnet -------------

resource "aws_subnet" "privatesub" {
  count = length(var.availability_zone)
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = var.private_cidr[count.index]
  availability_zone = var.availability_zone[count.index]
  tags = {
    Name = "STACKPRIV_${count.index}"
  }
}



#------creating Pblic subnet-------
resource "aws_subnet" "publicsub" {
  count = length(var.availability_zone)
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = var.public_cidr[count.index]
  availability_zone = var.availability_zone[count.index]
  tags = {
    Name = "STACKPUB_${count.index}"
  }
}

output "public_subnet_ids" {
  value = aws_subnet.publicsub[*].id
}

#------Creating Internet GAteway-------------
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "STACK_TGW"
  }
}


#--------Getting EIP---------

#Fetching data about a particaular EIP
data "aws_eips" "example" {
  filter {
    name   = "tag:Name"
    values = ["STACKEIP2"]
  }
}



output "EIP" {
  value = data.aws_eips.example.allocation_ids
}


#-----------Creating NAT gateway----------
resource "aws_nat_gateway" "NATGATE" {

  allocation_id = data.aws_eips.example.allocation_ids[0]
  subnet_id     = aws_subnet.publicsub[0].id

  tags = {
    Name = "STACKNATGATEWAY"
  }
  depends_on = [aws_internet_gateway.gw]
}


#------creating route table for public sub-------
resource "aws_route_table" "pubroutetable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

   tags = {
    Name = "STACKRT1"
  }
}

output "routetab" {
  value = aws_route_table.pubroutetable.id
}




  #----creating route table fro private subnet---------
  resource "aws_route_table" "privroutetable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.NATGATE.id
  }

  tags = {
    Name = "STACKRT2"
  }
}




#-----Assocatiating route table with public subnets ------
resource "aws_route_table_association" "ass" {
  subnet_id      = aws_subnet.publicsub[0].id
  route_table_id = aws_route_table.pubroutetable.id
}

resource "aws_route_table_association" "ass1" {
  subnet_id      = aws_subnet.publicsub[1].id
  route_table_id = aws_route_table.pubroutetable.id
}


#-------Associating private subnet with route table 
resource "aws_route_table_association" "ass2" {
  subnet_id      = aws_subnet.privatesub[0].id
  route_table_id = aws_route_table.privroutetable.id
}

resource "aws_route_table_association" "ass3" {
  subnet_id      = aws_subnet.privatesub[1].id
  route_table_id = aws_route_table.privroutetable.id
}



