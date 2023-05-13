#############################################################################################################################

provider "aws" {
region = "ap-south-1"
access_key = "AKIAVBJIWKILJVTEHEMS"
secret_key = "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"
}

########### Creating VPC #####################################################################

resource "aws_vpc" "cloudvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "cloudvpc"
  }
}

########## Creating Public and Private Subnet ################################################

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.cloudvpc.id
  cidr_block = "10.0.4.0/22"

  tags = {
    Name = "Public-Subnet"
  }
}
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.cloudvpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private-Subnet"
  }
}

############## Creating Security Group #########################################################

resource "aws_security_group" "cloudsg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.cloudvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "Cloud_Security_Group"
  }
}

############## Creating Internet Gateway ########################################################
resource "aws_internet_gateway" "cloud_igw" {
  vpc_id = aws_vpc.cloudvpc.id

  tags = {
    Name = "cloud_igw"
  }
}
############## Creating Public Route Table and associate with Public Subnet ######################
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.cloudvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloud_igw.id
  }

  tags = {
    Name = "Public-rt"
  }
}
resource "aws_route_table_association" "public-association" { 
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public-rt.id
}
############### Creating AWS Instance ############################################################
resource "aws_instance" "cloudinstance" {
  ami           = "ami-0b08bfc6ff7069aff"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.cloudsg.id]

  tags = {
    Name = "Cloud-india"
  }
}

resource "aws_eip" "cloud_eip" {
  instance = aws_instance.cloudinstance.id
  vpc      = true
}

resource "aws_instance" "dbinstance" {
  ami           = "ami-0b08bfc6ff7069aff"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.cloudsg.id]

  tags = {
    Name = "DB-instance"
  }
}
###################### Create Nat Gateway ########################################
resource "aws_eip" "nat_eip" {
  vpc      = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "Cloud Nat Gateway"
  }
}
#################### Create Private Root Table for Nat Gateway and associate with Private Subnet #############################
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.cloudvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private-rt"
  }
}
resource "aws_route_table_association" "private-association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private-rt.id
}

############################ Script Complete ###################################