#variable "AWS_ACCESS_KEY" {}

#variable "AWS_SECRET_KEY" {}


variable "AWS_REGION" {
  default = "us-east-1"
}

variable "PATH_TO_PRIVATE_KEY" {
  default = "clixx_key"
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "clixx_key.pub"
}

# variable "AMIS" {
#   type = map(string)
#   default = {
#     us-east-1 = "ami-08f3d892de259504d"
#     us-west-2 = "ami-06b94666"
#     eu-west-1 = "ami-844e0bf7"
#   }
# }

variable "ACCOUNTS" {
  type = map(string)
  default = {
    dev = 495599767034
    production = 242201295617
    uat = 222634402516
  }
}

#  variable "RDS_PASSWORD" {
#  }

# variable "INSTANCE_USERNAME" {
# }

variable "subnets" {
  type = list(string)
  default=[
    "subnet-018e197bd500d943a"
   
   ]
}

variable "instance_type"{
  default ="t2.micro"
}


# variable "vpc_id"{
#     default="vpc-0c6460b8c3c8fe62f"
# }

variable "ami" {
  default = "ami-056d6c51d3b7d21af"
}


variable "subnet" {
  type = list(string)
  default=[
    "subnet-018e197bd500d943a",
    "subnet-014c00ad60d4e3316"
   
   ]
}

variable "availability_zone" {
  type = list(string)
  description = "Avaialability zone"
  default = ["us-east-1a","us-east-1b"]
}


variable "private_cidr" {
  type = list(string)
  description = "private cidr"
  default = ["10.0.0.0/24","10.0.1.0/24"]
}


variable "public_cidr" {
  type = list(string)
  description = "public cidr"
  default = ["10.0.2.0/24","10.0.3.0/24"]
}

variable "environment" {
  default = "dev"
}