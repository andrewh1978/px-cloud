. aws-env.sh

aws ec2 delete-security-group --group-id $sg
aws ec2 delete-subnet --subnet-id $subnet
aws ec2 detach-internet-gateway --internet-gateway-id $gw --vpc-id $vpc
aws ec2 delete-internet-gateway --internet-gateway-id $gw
aws ec2 delete-route-table --route-table-id $routetable
aws ec2 delete-vpc --vpc-id $vpc
