resource "aws_vpc" "vpc_proj" {
  cidr_block = var.cidr
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc_proj.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc_proj.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw_table" {
  vpc_id = aws_vpc.vpc_proj.id
}

resource "aws_route_table" "RT_table" {
  vpc_id = aws_vpc.vpc_proj.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_table.id
  }
}

resource "aws_route_table_association" "rtal" {
  subnet_id      = aws_subnet.subnet1.id   # fixed here
  route_table_id = aws_route_table.RT_table.id  # fixed name
}

resource "aws_route_table_association" "rtal1" {
  subnet_id      = aws_subnet.subnet2.id   # fixed here
  route_table_id = aws_route_table.RT_table.id  # fixed name
}
resource "aws_security_group" "allow_tls" {
  name   = "websg"
  vpc_id = aws_vpc.vpc_proj.id

  tags = {
    Name = "web-sg"
  }
}

# Ingress Rule - Allow HTTP traffic from anywhere (IPv4)
resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"          # fixed typo from 0.0.0/0 to correct block
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# Ingress Rule - Allow SSH traffic (port 22) from anywhere (IPv6)
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = "::/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"   # changed from "ssh" to correct value "tcp"
}

# Egress Rule - Allow all IPv4 traffic
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Egress Rule - Allow all IPv6 traffic
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}
resource "aws_s3_bucket" "firstbucket" {
  bucket = "rimsha-terraform-bucket-20250718"
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.firstbucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.firstbucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.firstbucket.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example
  ]
}


resource "aws_instance" "ec2_instance" {
  ami                    = "ami-0f918f7e67a3323f0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]  # ✅ Correct reference
  subnet_id              = aws_subnet.subnet1.id              # ✅ Correct subnet ID
  user_data              = file("userdata.sh")  # ✅ Make sure file exists
}

resource "aws_instance" "ec2_instance2" {
  ami                    = "ami-0f918f7e67a3323f0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]  # ✅ Correct reference
  subnet_id              = aws_subnet.subnet2.id              # ✅ FIXED missing `.id`
  user_data              = file("userdata1.sh") # ✅ Make sure file exists
}