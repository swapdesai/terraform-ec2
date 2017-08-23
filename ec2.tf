provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "ap-southeast-2"
}

# Create VPC
resource "aws_vpc" "ec2_vpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true

	tags {
    Name = "ec2_vpc"
  }
}

# Public subnets
resource "aws_subnet" "ec2_public" {
	vpc_id = "${aws_vpc.ec2_vpc.id}"

	cidr_block = "10.0.0.0/24"
	#availability_zone = "ap-southeast-2a"

	tags {
    Name = "ec2_subnet_public"
  }
}

# Create Network ACL
# resource "aws_network_acl" "ec2" {
#   vpc_id = "${aws_vpc.ec2_vpc.id}"
#
#   subnet_ids = [ "${aws_subnet.ec2_public.id}" ]
#
#   tags {
#     Name = "ec2_network_acl"
#   }
# }

# Creates entries (a rule) in a network ACL
/*
resource "aws_network_acl_rule" "ec2_http" {
  network_acl_id = "${aws_network_acl.ec2.id}"
  egress         = true
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "ec2_ssh" {
  network_acl_id = "${aws_network_acl.ec2.id}"
  egress         = false
  rule_number    = 200
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}
*/

# Create Internet Gateway
resource "aws_internet_gateway" "ec2_internet_gateway" {
	vpc_id = "${aws_vpc.ec2_vpc.id}"

	tags {
    Name = "ec2_internet_gateway"
  }
}

# Routing table for public subnet
resource "aws_route_table" "ec2_public" {
	vpc_id = "${aws_vpc.ec2_vpc.id}"

  route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.ec2_internet_gateway.id}"
	}

	tags {
    Name = "ec2_route_table_public"
  }
}

# Route Table association to the subnet
resource "aws_route_table_association" "ec2_public" {
	subnet_id = "${aws_subnet.ec2_public.id}"
	route_table_id = "${aws_route_table.ec2_public.id}"
}

# Create Security Group
resource "aws_security_group" "ec2_security_group" {
  vpc_id = "${aws_vpc.ec2_vpc.id}"

  name = "ec2_ssh"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

# Create SSH key pair
resource "aws_key_pair" "deployer" {
  key_name   = "ec2_key_name"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCx0PZMUM+ML5K3SW1mMHiB3L/v3Xh91sAiHFlt7Qf4++w999RMANP5GIbLRyYqc1KqJlreJQsv1ChuLn059gNdtz4l551jw56lAotuFUIOZ3LhTlw1XlX/bQTYGJAfxzgqs3BMPVBG3eZVtqY3gk2cI+w+SvAy0WYGVrZPuPJfmPL5gKU+ys8IvhLUqXKfUXWx8tu77Ni71/WjRfPqNHyIr6sPt6K03LOF03Qm9EQWHolf1wKesg+pUs1i0HEr0DC34WYWJUiDG1f/flkPvKqQa57rmIX2gMZicWEzyInPqZc8+dXDCoO4khjPzb0U1CImAiUYphhESIOOZ1rhVc+X swadesai@au10154"
}


# Create EC2 instance
resource "aws_instance" "web" {
  ami           = "ami-30041c53"
  instance_type = "t2.micro"
  key_name      = "ec2_key_name"

  # When using subnet_id and using a security groups from a non-default VPC, need to use group id instead of name
  #security_groups = [ "ec2_security_group" ]
  security_groups = [ "${aws_security_group.ec2_security_group.id}" ]

  subnet_id = "${aws_subnet.ec2_public.id}"

  associate_public_ip_address = true

  # Install Apache using a bash script
  user_data = "${file("example.txt")}"
  #user_data = "${template_file.httpd.rendered}"

  tags {
    name = "ec2_instance"
  }
}
