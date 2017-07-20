provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
}


# Availability Zones

data "aws_availability_zones" "available" {}

resource "aws_vpc" "vishman_vpc"{
  cidr_block = "10.0.0.0/16"

  tags{
    Name = "vishman_vpc"
  }
}


# VPC
resource "aws_internet_gateway" "vishman_igw"{
  vpc_id = "${aws_vpc.vishman_vpc.id}"

  tags{
    Name = "vishman_igw"
  }
}

# Routes

#Public
resource "aws_route_table" "vishman_rt_public"{
  vpc_id = "${aws_vpc.vishman_vpc.id}"
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.vishman_igw.id}"
  }
  tags{
    Name = "vishman_rt_public"
  }
}


# Private
resource "aws_route_table" "vishman_rt_private"{
  vpc_id = "${aws_vpc.vishman_vpc.id}"
  tags{
    Name = "vishman_rt_private"
  }
}

# Subnet

# public
resource "aws_subnet" "vishman_sn_public_a"{
  vpc_id = "${aws_vpc.vishman_vpc.id}"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  tags{
    Name = "vishman_sn_public_a"
  }
}

resource "aws_subnet" "vishman_sn_public_b"{
  vpc_id = "${aws_vpc.vishman_vpc.id}"
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  tags{
    Name = "vishman_sn_public_b"
  }
}

# private
resource "aws_subnet" "vishman_sn_private_a"{
  vpc_id = "${aws_vpc.vishman_vpc.id}"
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  tags{
    Name = "vishman_sn_private_a"
  }
}

resource "aws_subnet" "vishman_sn_private_b"{
  vpc_id = "${aws_vpc.vishman_vpc.id}"
  cidr_block = "10.0.4.0/24"
  map_public_ip_on_launch = false
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  tags{
    Name = "vishman_sn_private_b"
  }
}

resource "aws_subnet" "vishman_sn_rds1"{
  vpc_id = "${aws_vpc.vishman_vpc.id}"
  cidr_block = "10.0.5.0/24"
  map_public_ip_on_launch = false
  availability_zone = "${data.aws_availability_zones.available.names[3]}"
  tags{
    Name = "vishman_sn_rds1"
  }
}


# Route_Subnet Association

resource "aws_route_table_association" "rt_sn_public_a"{
  subnet_id = "${aws_subnet.vishman_sn_public_a.id}"
  route_table_id = "${aws_route_table.vishman_rt_public.id}"
}

resource "aws_route_table_association" "rt_sn_public_b"{
  subnet_id = "${aws_subnet.vishman_sn_public_b.id}"
  route_table_id = "${aws_route_table.vishman_rt_public.id}"
}

resource "aws_route_table_association" "rt_sn_private_a"{
  subnet_id = "${aws_subnet.vishman_sn_private_a.id}"
  route_table_id = "${aws_route_table.vishman_rt_private.id}"
}

resource "aws_route_table_association" "rt_sn_private_b"{
  subnet_id = "${aws_subnet.vishman_sn_private_b.id}"
  route_table_id = "${aws_route_table.vishman_rt_private.id}"
}

#resource "aws_db_subnet_group" "db_sn_rds"{
# name = "db_sn_rds"
#  subnet_ids = ["${aws_subnet.vishman_sn_rds1.id }"]  
#  tags{
#    Name = "db_sn_rds"
#  }
#}
#For this group to work we need to add minimum two subnets to it

#Securiry Groups
resource "aws_security_group" "vishman_sg_public"{
  name = "vishman_sg_public"
  description = "This is public facing group"
  vpc_id = "${aws_vpc.vishman_vpc.id}"
  ingress{
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress{
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "vishman_sg_private"{
  name = "vishman_sg_private"
  description = "This is private facing group"
  vpc_id = "${aws_vpc.vishman_vpc.id}"
  ingress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

resource "aws_instance" "vishman_compute_dev"{
  instance_type = "${var.instance_type_dev_web}"
  ami = "${var.ami_web}"
  tags{
    Name = "vishman_compute_dev"
  }
}






