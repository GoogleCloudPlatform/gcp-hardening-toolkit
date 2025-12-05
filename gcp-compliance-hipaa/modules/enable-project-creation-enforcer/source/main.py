import base64
import json
import os

from google.cloud import service_usage_v1

def enable_cloud_asset_api(event, context):
    """Triggered from a message on a Cloud Pub/Sub topic.
    Args:
         event (dict): Event payload.
         context (google.cloud.functions.Context): Metadata for the event.
    """
    pubsub_message = base64.b64decode(event['data']).decode('utf-8')
    log_entry = json.loads(pubsub_message)
    try:
        project_id = log_entry['protoPayload']['request']['project']['projectId']

        print(f"Enabling Cloud Asset API for project: {project_id}")

        client = service_usage_v1.ServiceUsageClient()
        service_name = f"projects/{project_id}/services/cloudasset.googleapis.com"

        request = service_usage_v1.EnableServiceRequest(
            name=service_name
        )

        try:
            operation = client.enable_service(request=request)
            print(f"Waiting for operation {operation.name} to complete...")
            response = operation.result()
            print(f"Successfully enabled Cloud Asset API for project {project_id}: {response}")
        except Exception as e:
            print(f"Error enabling Cloud Asset API for project {project_id}: {e}")
    except KeyError:
        print("Error parsing log entry:")
        print(log_entry)
