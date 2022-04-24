# configure the aws provider with credentials

provider "aws" {
	region = "us-west-2"
	access_key = ""
	secret_key = ""
}

# create first vpc 

resource "aws_vpc" "sec-vpc-1" {
  cidr_block = "10.0.0.0/16"
  tags = {
   Name = "sec-west-2a"
  }
}


#create internet gataway and toute tables

resource "aws_internet_gateway" "sec-gw-1" {
  vpc_id = aws_vpc.sec-vpc-1.id
  }

# Create custom route table

resource "aws_route_table" "sec-rt-1" {
  vpc_id = aws_vpc.sec-vpc-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sec-gw-1.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.sec-gw-1.id
  }

  tags = {
    Name = "gw-sec-1"
  }
}

# subnet #1 created here

resource "aws_subnet" "sec-subnet-1" {
  vpc_id = aws_vpc.sec-vpc-1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
     Name = "sec-sbnet1-west-2"
  }
}

# associate subnet with route table

resource "aws_route_table_association" "secsubrt-1" {
  subnet_id      = aws_subnet.sec-subnet-1.id
  route_table_id = aws_route_table.sec-rt-1.id
}

#create security group to allow port 22, 80 and 443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.sec-vpc-1.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
# }

ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_websec"
  }
}

# create a network interface with an IP in the subnet that was created above

resource "aws_network_interface" "sec-ptt-nic-1" {
  subnet_id       = aws_subnet.sec-subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# assign elastic IP to the network interface created above

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.sec-ptt-nic-1.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.sec-gw-1]
}

# ubuntu server for blacktech

resource "aws_instance" "bth-svr" {
  ami = "ami-07dd19a7900a1f049"
  instance_type = "t2.medium"
  availability_zone = "us-west-2a"
  #key_name = "main-key"
  tags = {
   Name = "blacktech"
  }
 
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.sec-ptt-nic-1.id
  }
}
