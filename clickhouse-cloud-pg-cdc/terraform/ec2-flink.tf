resource "aws_security_group" "flink_ec2" {
  name        = "flink-ec2-sg"
  description = "Allow SSH, Flink UI, and all egress"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Flink UI
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "flink_master" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2, update as needed
  instance_type = "t3.medium"
  subnet_id     = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.flink_ec2.id]
  associate_public_ip_address = true

  tags = {
    Name = "flink-master"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install java-openjdk11 -y
    wget https://archive.apache.org/dist/flink/flink-1.17.1/flink-1.17.1-bin-scala_2.12.tgz
    tar -xzf flink-1.17.1-bin-scala_2.12.tgz
    mv flink-1.17.1 /opt/flink
    echo 'export PATH=$PATH:/opt/flink/bin' >> /etc/profile
    # Optionally, configure S3 credentials here or via IAM role
    cd /opt/flink
    ./bin/start-cluster.sh

    # get java program which writes to pg
  EOF

  depends_on = [
    aws_db_instance.flink_pg
  ]
}