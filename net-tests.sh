#!/bin/bash

IP=''

cd bootstrap; source ./env.sh; cd ..
# 1. HTTPS works, plain HTTP does not
curl -sk -o /dev/null -w "https: %{http_code}\n" https://$IP:8443/login
curl -s --max-time 5 http://$IP:8443/login; echo "plain http exit code: $?"
# 2. Security headers added by the app
curl -skI https://$IP:8443/login | grep -i -E 'strict-transport|x-frame|content-security|x-content-type|cache-
control|referrer'
# 3. SSH and the old port are closed (a timeout means the security group dropped the packet)
for P in 22 8080; do timeout 5 bash -c "</dev/tcp/$IP/$P" && echo "port $P OPEN" || echo "port $P closed";
done
# 4. Lockout: six wrong passwords. Expect 200 five times, then 429
for i in 1 2 3 4 5 6; do curl -sk -o /dev/null -w "%{http_code} " -d "username=admin&password=wrong"
https://$IP:8443/login; done; echo
# 5. The rules you built
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=nimbus-sg --query
'SecurityGroups[0].GroupId' --output text)
aws ec2 describe-security-groups --group-ids $SG --query 'SecurityGroups[0].[IpPermissions[].
[FromPort,IpRanges[].CidrIp],IpPermissionsEgress[].[FromPort]]' --output json
aws ec2 describe-vpc-endpoints --filters Name=tag:Name,Values=lab01-s3 --query 'VpcEndpoints[].
[VpcEndpointType,State]' --output text