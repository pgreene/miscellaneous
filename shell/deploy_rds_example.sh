#!/bin/zsh
## --------------------------------------------------------------------------------- ##
## --- Purpose: Deploy RDS databases & set up table schemas ------------------------ ##
## --- Script: deploy.sh ----------------------------------------------------------- ##
## --- Author: DevOps -------------------------------------------------------------- ##
## --------------------------------------------------------------------------------- ##

START=$(date +%s)

#CREATE_SQL_FILES=`cd ./files/create-sql/ && for n in *; do printf '%s\t\n' "$n"; done`
#INSERT_SQL_FILES=`cd ./files/insert-sql/ && for n in *; do printf '%s\t\n' "$n"; done`

CREATE_ARRAY=(`ls -lh ./files/create-sql/ | awk '{ print $9 }'`)
INSERT_ARRAY=(`ls -lh ./files/insert-sql/ | awk '{ print $9 }'`)

echo $CREATE_ARRAY
echo $INSERT_ARRAY

rm -rf ./.terraform & rm -rf .terraform* 
terraform init
terraform providers lock
terraform apply -auto-approve

# Set variables after RDS is set up
bastion_ip="qa-bastion.won.popreach.com"
#rds_endpoint="qa-gcand.cluster-cg10idcbm0rj.us-east-1.rds.amazonaws.com"
rds_endpoint=`terraform output endpoint | sed 's/"//g' | sed 's/endpoint\ \=//g' | sed 's/   //g'`
rds_user=`cat secrets.tf | grep -i default | awk 'FNR == 1 {print}' | sed 's/"//g' | sed 's/default\ \=//g' | sed 's/   //g'`
rds_password=`cat secrets.tf | grep -i default | awk 'FNR == 2 {print}' | sed 's/"//g' | sed 's/default\ \=//g' | sed 's/   //g'`

echo $bastion_ip
echo $rds_endpoint
echo $rds_user
echo $rds_password

# Create SSH tunnel & create databases
ssh -oStrictHostKeyChecking=no -p 2233 -i ~/.ssh/won-bastion-qa.pem -C -N ec2-user@$bastion_ip -L 3306:$rds_endpoint:3306 &

sleep 5

for i in "${CREATE_ARRAY[@]}"; do
    echo "Creating $i ... "
    cat ./files/create-sql/$i | mysql -u $rds_user -p$rds_password -h 127.0.0.1
done

sleep 1

for i in "${INSERT_ARRAY[@]}"; do
    echo "Inserting $i ... "
    cat ./files/insert-sql/$i | mysql -u $rds_user -p$rds_password -h 127.0.0.1
done

echo "Verifying Table Schemas were created ..."
mysql -u $rds_user -p$rds_password -h 127.0.0.1 -e "SHOW DATABASES;"

# Terminate SSH Tunnel
pkill ssh

END=$(date +%s)
DIFF=$(($END-$START))
MIN=$(($DIFF/60))
echo "$(date): It took $MIN minute(s) to deploy $rds_endpoint"
echo "$(date): $DIFF second(s)"

