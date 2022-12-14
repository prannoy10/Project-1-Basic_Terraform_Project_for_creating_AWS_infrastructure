
provider "aws" {
  region = "ap-south-1"
  access_key = "" #fill it
  secret_key = "" #fill it
}

#create variable for subnet_prefix
variable "subnet_prefix" {
  description = "cidr block for the subnet"
  #default = #value which terraform is going to give when not entered anything
  #type = String  #It supports other different types like numbers,booleans, lists,maps,sets,objects,tuples etc 
}

#1.create vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block = var.subnet_prefix    #"10.0.0.0/16" # var.subnet_prefix
  tags = {
    Name = "production"
  }
}

#2.create Internet gateway referencing vpc
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id          #reference aws_vpc.<vpc name>.id
}

#3.create route table
resource "aws_route_table" "prod-route-table" {   #name of RT
  vpc_id = aws_vpc.prod-vpc.id   #mention vpc id

  route {
    cidr_block = "0.0.0.0/0"     #set default route by using 0.0.0.0 which means all IPv4 traffic will be sent to the Internet gateway
    gateway_id = aws_internet_gateway.gw.id   #gw is gateway created above
  }
  route {
    ipv6_cidr_block        = "::/0"   #ipv6 default route
    gateway_id = aws_internet_gateway.gw.id #so our default route for ipv4 and ipv6 is going to go to Internet gateway so we can get out of internet or traffic from the subnet that we are going to create can get out to the internet
  }

  tags = {
    Name = "Prod"
  }
}


#4.Let's create a subnet

resource "aws_subnet" "subnet-1" {
   vpc_id = aws_vpc.prod-vpc.id
   cidr_block = var.subnet_prefix
   availability_zone = "ap-south-1a"
   
   tags = {
      Name = "prod-subnet"
   }
}

#5.associate subnet with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

#6.Create Security group  # only allow certain protocols that you need.
resource "aws_security_group" "allow_web" { # SG name allow_web_traffic
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

#So we have ingress and egress policy
  ingress {
    description      = "HTTPS from VPC"   #HTTPS traffic as 443 port used
    from_port        = 443    #from and to means allow range of ports
    to_port          = 443    # this means we are allowing only 443 port
    protocol         = "tcp"    #can be tcp or udp
    cidr_blocks      = ["0.0.0.0/24"] #Any IP address can access
    #ipv6_cidr_blocks = ["0.0.0.0/24"]
  }

  ingress {
    description      = "HTTP from VPC"   #HTTP traffic as 443 port used
    from_port        = 80    #from and to means allow range of ports
    to_port          = 80    # this means we are allowing only 443 port
    protocol         = "tcp"    #can be tcp or udp
    cidr_blocks      = ["0.0.0.0/24"] #Any IP address can access
    #ipv6_cidr_blocks = ["0.0.0.0/24"]
  }

  ingress {
    description      = "ssh from VPC"   #HTTPS traffic as 443 port used
    from_port        = 22    #from and to means allow range of ports
    to_port          = 22    # this means we are allowing only 443 port
    protocol         = "tcp"    #can be tcp or udp
    cidr_blocks      = ["0.0.0.0/24"] #Any IP address can access
    #ipv6_cidr_blocks = ["0.0.0.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"    #-1 means any protocol in egress
    cidr_blocks      = ["0.0.0.0/0"]   #allow all ports in egress direction
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"   #
  }
}

#7.create a custom network interface with an IP in the subnet that was created in step 4(creating subnet).

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id  #subnet-1 is created
  private_ips     = ["10.0.200.50"]   #specify what IP we want to give the server. We can pick any IP within the subnet
  security_groups = [aws_security_group.allow_web.id]  #allow_web is security group created

}

#we have now assigned private IP
#Now we need to assign public IP so that anybody on internet can access it.

#8.Assign an elastic IP to the network interface in step 7. (elastic IP in AWS is just a public IP address that routable on the internet)
resource "aws_eip" "one" {
  vpc                       = true # if elastic IP(eip) is in vpc or not
  network_interface         = aws_network_interface.web-server-nic.id #specify what network interface we want to assign to (one we created in step 7)
  associate_with_private_ip = "10.0.200.50"   # assign same private IP mentioned above
  depends_on =  [aws_internet_gateway.gw] #no need to specify id, it is just to ensure in case order is not in place
}# when you mention depends_on parameter, you need to pass it on list ie inside [] bracket as you can you can put in many resources
#like depends_on = [aws_internet_gateway.gw,vpc,subnet etc]

output "server_public_ip" {  #Now assign value from terraform state show
   value = aws_eip.one.public_ip
}

#AWS eip relies on the deployment of internet gateway. So if you create a elastic IP and assigned it to a device that's on a vpc/subnet
#that doesn't have a internet gateway, it will throw an error. So in this case, order also matter, internet gateway must be be defined
#before eip unless we mention "depends_on". 


#9.Create rhel server(ec2) and install/enable apache2
 
resource "aws_instance" "web-server-ec2-instance" {
  ami           = "ami-05c8ca4485f8b138a"         #ami-05c8ca4485f8b138a for rhel and "ami-062df10d14676e201"  for ubuntu
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"  #recommend to hardcode it. else aws will randomly assign resources in different AZ. Like there
  #may be case where subnet was deployed in one AZ and interface and different AZ.
  #Now also mention key pair which we created and downloaded.
  key_name = "main-key"

  network_interface{
    device_index = 0   #the first network interface associated with this device
    network_interface_id = aws_network_interface.web-server-nic.id
  }

tags = {         
     Name= "web-server"
  } 






#Now we are going to tell terraform, on deployment of the ec2 server, run few commands on server so we automatically install apache.
 #Now we can run all the commands after EOF below
 # user_data = <<EOF   
 #   #!/bin/bash
 #   sudo apt update -y 
 #   sudo apt install apache2 -y
 #   sudo systemctl start apache2
 #   sudo bash -c "echo your very first web server > /var/www/html/index.html"               
 # EOF

user_data = <<EOF
                #!/bin/bash
                yum update -y
                yum install -y httpd.x86_64
                systemctl start httpd.service
                systemctl enable httpd.service
                echo "Hello from Terraform deployed website!" > /var/www/html/index.html"
                EOF

}

output "server_private_ip" {
  value = aws_instance.web-server-ec2-instance.private_ip
  #value = aws_instance.web-server-ec2-instance.id  # This won't work as each output can have only 1 input. So we need to create another output 
}

output "server_id" {
  value = aws_instance.web-server-ec2-instance.id
}
