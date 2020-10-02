# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  #Get the keys from console.aws.amazon.com/iam > security credentials > Access Keys
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

#We define variables that are gonna be assigned a value in the 'terraform.tfvars' file later on.
variable "aws_access_key" { 
  description = "AWS Access Key"
  type        = string
}
variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
}

#In order to access your server through SSH later, please follow the step below :

#Remember to chose AZ first, in our case: us-east-1
#Create an EC2 Key Pair by going to console.aws.amazon.com/ec2 > Networks & Security > Key Pairs > Chose .pem file format, for instance, name it "aws-ec2-main-key" 
#This key is going to allow us to connect our server once we deploy it

# 1. Create VPC
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

resource "aws_vpc" "prod-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "production"
  }
}

# 2. Create Internet Gateway
# To send traffic out to the internet
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway

resource "aws_internet_gateway" "prod-internet-gateway" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "production"
  }
}

# 3. Create Custom Route Table (optional)
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0" #Create a default route
    gateway_id = aws_internet_gateway.prod-internet-gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.prod-internet-gateway.id
  }

  tags = {
    Name = "prod"
  }
}

# 4. Create a Subnet
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a" #optional property

  tags = {
    Name = "prod-subnet"
  }
}


# 5. Associate subnet with Route Table
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association

resource "aws_route_table_association" "association-1" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create Security Group to allow port 22,80,443
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #Change to 0.0.0.0/0 so any IP address can access it
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
    protocol    = "-1" #-1 by default mean any protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a network interface with an ip in the subnet that was created
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface
# Provides an Elastic network interface (ENI) resource.

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# 8. Assign an elastic IP to the network interface created in step 7
#    Elastic IP in the Amazon world is just a public IP address
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  #EIP may require IGW to exist prior to association. Use depends_on to set an explicit dependency on the IGW.
  depends_on                = [aws_internet_gateway.prod-internet-gateway] #We want to reference the whole object and not just the id
}

#Print out the public IP on the console when we run "terraform apply"
output "server_public_ip" {
  value = aws_eip.one.public_ip  #Obtained using "terraform state list" and "terraform state show aws_eip.one"
}

# 9. Create Ubuntu server and install/enable apache2
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "web-server-instance" {
  ami           = "ami-0817d428a6fb68645" #Get the ami id from AWS Console ec2/ > Ubuntu 18.04 LTS
  instance_type = "t2.micro" #because included in free tier
  availability_zone = "us-east-1a" #Must match our subnet AZ
  key_name = "aws-ec2-main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }
  #Doc:https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#network-interfaces
  
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
               sudo bash -c 'echo Hello World ! Welcome to this web server powered by Terraform through AWS > /var/www/html/index.html'
              EOF

  tags = {
    Name = "ubuntu-web-server"
  }
}