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


# Route_Subnet Association

resource "aws_route_table_association" "rt_sn_public_a"{
  subnet_id = "${aws_subnet.vishman_sn_public_a.id}"
  route_table_id = "${aws_route_table.vishman_rt_public.id}"
}

resource "aws_route_table_association" "rt_sn_public_b"{
  subnet_id = "${aws_subnet.vishman_sn_public_b.id}"
  route_table_id = "${aws_route_table.vishman_rt_public.id}"
}


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


# Key Pair
resource "aws_key_pair" "vishman_auth_key"{
  key_name = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

# Server
resource "aws_instance" "vishman_compute_dev"{
  instance_type = "${var.instance_type_dev_web}"
  ami = "${var.ami_web}"
  tags{
    Name = "vishman_compute_dev"
  }

  key_name = "${aws_key_pair.vishman_auth_key.id}"
  vpc_security_group_ids = ["${aws_security_group.vishman_sg_public.id}"]
  subnet_id = "${aws_subnet.vishman_sn_public_a.id}"

  provisioner "local-exec"{
    command = <<EOD
cat <<EOF > aws_hosts
[dev]
${aws_instance.vishman_compute_dev.public_ip}
EOF
EOD
  }

  provisioner "local-exec"{
    command = "sleep 6m && ansible-playbook -i aws_hosts deploy.yml"
  }
}
