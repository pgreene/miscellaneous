#!/bin/zsh
# ------------------------------------------------------ #
# --- Purpose: SSM Connection to any EC2 Instance ------ #
# ------------ that supports it ------------------------ #
# ------------------------------------------------------ #


count_p=1
IFC=$'\n'
PROFILES=(`grep -E '^\[' ~/.aws/credentials | sed 's/\[//' | sed 's/\]//'`)
PROFILE_LIST=($(sort -k2 <<<"${PROFILES[*]}"))
for row in "${PROFILE_LIST[@]}"
do
 printf "%2d: %10s\n" $count_p ${row}
 count_p=$((count_p+1))
done

echo ""
echo -n "Select your AWS PROFILE: "
read CHOICES
unset IFC

read PROFILE <<<$(IFC="\t"; echo $PROFILE_LIST[$CHOICES])

if [ -z "$PROFILE" ] 
then 
  echo "SELECTION CANNOT BE BLANK"
  exit 1
else
  echo YOU SELECTED: $PROFILE
fi

count_i=1
IFS=$'\n'

echo ""
echo "Please wait while list of EC2 Instances are found in $PROFILE ..."
echo ""

echo "Which region; us-east-2 or us-east-1? Type the region you want: "
read AWS_REGION
echo "List of EC2 Instances in AWS $PROFILE $AWS_REGION:"
LIST_UNSORTED=( $(aws --region $AWS_REGION --profile $PROFILE --output text ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].{InstanceId:InstanceId PrivateIpAddress:PrivateIpAddress Name:Tags[?Key=='Name']|[0].Value}") )
LIST=($(sort -k2 <<<"${LIST_UNSORTED[*]}"))

for row in "${LIST[@]}"
do
 printf "%2d: %50s\n" $count_i ${row}
 count_i=$((count_i+1))
done

echo ""
echo -n "SELECT EC2 INSTANCE YOU WANT TO CONNECT TO: "
read SELECTION
unset IFS

read HOSTNAME IP <<<$(IFS="\t"; echo $LIST[$SELECTION])
echo "..."
if [ -z "$HOSTNAME" ] 
then 
  echo "SELECTION CANNOT BE BLANK"
  exit 1
else
  echo YOU SELECTED: $HOSTNAME
fi
