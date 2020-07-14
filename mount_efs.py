import boto3


client = boto3.client('ecs')
response = client.describe_task_definition(taskDefinition='mail-prod')
task = response['taskDefinition']
container_defs = task['containerDefinitions']

for idx, container in enumerate(container_defs):
		if container['name'] == 'mail-prod':
			mailtrain_idx = idx

if len(task['volumes']) == 0:
		volume_config = 	[{
			"name": "efs",
			"efsVolumeConfiguration": {
				"fileSystemId": "fs-e673da9e",
				"rootDirectory": "/"
			}
		}]
		container_defs[mailtrain_idx]['mountPoints'] = [{'sourceVolume': 'efs', 'containerPath': '/app/server/files'}]
else:
		volume_config = task['volumes']


response = client.register_task_definition(
    family=task['family'],
    executionRoleArn=task['executionRoleArn'],
    networkMode=task['networkMode'],
    containerDefinitions=container_defs,
    volumes=volume_config,
    requiresCompatibilities=task['requiresCompatibilities'],
    cpu=task['cpu'],
    memory=task['memory'],
    tags=[
    	{
        'key': 'Application',
      	'value': 'mail'
      },
      {
        'key': 'Environment',
      	'value': 'prod'
      }
    ]
)
