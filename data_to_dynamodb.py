# !pip install boto3

import boto3
import json

access_key="AKIAWEI56H2TMQQPD7UO"
secret_access_key="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"

session=boto3.Session(aws_access_key_id=access_key,aws_secret_access_key=secret_access_key, region_name='us-east-1')
client_dynamo=session.resource('dynamodb')
table=client_dynamo.Table('student_data')

records=""
with open('student_data.json','r') as datafile:
  records=json.load(datafile)

count=0
for i in records:
  i['id']=count
  print(i)
  response=table.put_item(Item=i)
  count+=1