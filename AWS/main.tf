
terraform {

  backend "s3" {
    
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# load config file
locals {
  input_file         = "./config.yml"
  input_file_content = fileexists(local.input_file) ? file(local.input_file) : "NoInputFileFound: true"
  input              = yamldecode(local.input_file_content)
}


# Configure the AWS Provider
provider "aws" {
  region     = local.input.access.region
  access_key = local.input.access.access_key
  secret_key = local.input.access.secret_key
}


data "aws_vpc" "selected" {
  state = "available"
  default = true
}

resource "aws_security_group" "public" {
  count = length(local.input.security_groups)
  name        = local.input.security_groups[count.index].name
  description = local.input.security_groups[count.index].description
  vpc_id      = data.aws_vpc.selected.id


  dynamic "ingress" {
    for_each = local.input.security_groups[count.index].rules
    content {
      from_port        = ingress.value["port"]
      to_port          = ingress.value["port"]
      protocol         = ingress.value["protocol"]
      cidr_blocks       = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    ManagedBy   = "terraform"
  }
  # tags = { for index, tag in local.input.security_groups[0].tags : (tag.key) => tag.value}
}


# filter image 
data "aws_ami" "filtred_amis" {
  most_recent = true

  count = length(local.input.ec2_instances)

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "name"
    values = [local.input.ec2_instances[count.index].name]
  }

  filter {
    name   = "architecture"
    values = [local.input.ec2_instances[count.index].architecture]
  }

  filter {
    name   = "virtualization-type"
    values = [local.input.ec2_instances[count.index].virtualization-type]
  }

  owners = [local.input.ec2_instances[count.index].owner]

}

# get exiting key pair
data "aws_key_pair" "access_key_name" {
  key_name = local.input.access.key_name
}


# attache volumes
resource "aws_volume_attachment" "ebs_att" {
  count           = length(local.input.ec2_instances)
  device_name = local.input.volume.device_name
  volume_id   = aws_ebs_volume.volumes[count.index].id
  instance_id = aws_instance.ec2_instances[count.index].id
  # skip_destroy = true
  stop_instance_before_detaching = true
}

# create volumes
resource "aws_ebs_volume" "volumes" {
  count           = length(local.input.ec2_instances)
  availability_zone = local.input.volume.zone
  size              = local.input.volume.size

  tags = {
    Name = local.input.ec2_instances[count.index].tag
  }
}

# create ec2 instances
resource "aws_instance" "ec2_instances" {
  count           = length(data.aws_ami.filtred_amis)
  ami             = data.aws_ami.filtred_amis[count.index].id
  instance_type   = local.input.ec2_instances[count.index].instance_type
  key_name        = data.aws_key_pair.access_key_name.key_name
  security_groups = local.input.ec2_instances[count.index].security_group
  tags = {
    Name = local.input.ec2_instances[count.index].tag
    group = local.input.ec2_instances[count.index].group
  }

  depends_on = [
    aws_security_group.public
  ]
}


# print result 
output "ec2_instances_created" {
  value = {
    for k, v in aws_instance.ec2_instances : k => {
      public_ip       = v.public_ip
      public_dns      = v.public_dns
      tags            = v.tags
      security_groups = v.security_groups
    }
  }
}