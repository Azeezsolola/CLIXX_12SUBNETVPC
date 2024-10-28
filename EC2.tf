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

