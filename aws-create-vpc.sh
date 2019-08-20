# Set the AWS region
AWS_DEFAULT_REGION=eu-west-1

# Do not change below this line
vpc=$(aws --output json ec2 create-vpc --cidr-block 192.168.99.0/24 | json Vpc.VpcId)
subnet=$(aws --output json ec2 create-subnet --vpc-id $vpc --cidr-block 192.168.99.0/24 | json Subnet.SubnetId)
gw=$(aws --output json ec2 create-internet-gateway | json InternetGateway.InternetGatewayId)
aws ec2 attach-internet-gateway --vpc-id $vpc --internet-gateway-id $gw
routetable=$(aws --output json ec2 create-route-table --vpc-id $vpc | json RouteTable.RouteTableId)
aws ec2 create-route --route-table-id $routetable --destination-cidr-block 0.0.0.0/0 --gateway-id $gw
aws ec2 associate-route-table  --subnet-id $subnet --route-table-id $routetable
sg=$(aws --output json ec2 create-security-group --group-name SSHAccess --description "Security group for SSH access" --vpc-id $vpc | json GroupId)
aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port 32678 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port 30900 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port 30950 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sg --protocol all --cidr 192.168.99.0/24

ami=$(aws --output json ec2 describe-images --owners 679593333241 --filters Name=name,Values='CentOS Linux 7 x86_64 HVM EBS*' Name=architecture,Values=x86_64 Name=root-device-type,Values=ebs --query 'sort_by(Images, &Name)[-1].ImageId' --output text)

cat <<EOF >aws-env.sh
vpc=$vpc
subnet=$subnet
gw=$gw
routetable=$routetable
sg=$sg
ami=$ami
AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
export vpc subnet gw routetable sg ami AWS_DEFAULT_REGION
EOF
