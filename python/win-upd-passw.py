# -------------------------------------------------------------------------- #
# --- Author: prdgreene@gmail.com -------------------------------------- --- #
# --- Purpose: Update RDP Windows User Password in AWS EC2 ----------------- #
# ------------ You must get the instance ID(s) of the servers from AWS ----- #
# -------------------------------------------------------------------------- #

import boto3


AWS_PROFILE = input("Enter your local AWS Profile Name: ") 
AWS_REGION = input("Enter the AWS REGION where the host resides (us-east-1 or eu-west-1): ")
INSTANCE_IDS = input("Enter the Instance ID aka Host (example; i-01234 OR if more than 1 \"i-01234\" \"i-05678\"): ")
#ENV = input("Enter the Environment you want to update your RDP User Password on (Example: dev, qa, uat): ")
WIN_USR = input("Enter your Windows RDP User Name: ")
WIN_PW = input("Enter your new Windows RDP Password: ")

boto3.setup_default_session(profile_name=AWS_PROFILE)
ssm_client = boto3.client('ssm',region_name=AWS_REGION)

response = ssm_client.send_command(
            InstanceIds=[INSTANCE_IDS],
            #Targets=[
        	#	{
            #		'Key': 'Env',
            #		'Values': [
            #    		ENV,
            #		]
        	#	},
    		#],
            DocumentName='AWS-RunPowerShellScript',
            DocumentVersion='1',
            #OutputS3BucketName='dbdx-ssm-output', 
            #OutputS3KeyPrefix=[INSTANCE_IDS],
            #Parameters={'commands': ['net user WIN_USR WIN_PW'], 'executionTimeout':['3600']} 
            Parameters={
        		'commands': [
            		'net user '  + str(WIN_USR) + ' ' + str(WIN_PW)
        		]
    		}
    		)

#command_id = response['Command']['CommandId']
         
#output = ssm_client.get_command_invocation(
#      CommandId=command_id,
#      InstanceId=INSTANCE_IDS,
#    )
#print(output)

print ("You have invoked the change password cmd. Please try RDP-ing into the host now to see if it was successful.")
