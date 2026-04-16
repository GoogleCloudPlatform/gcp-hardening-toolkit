"""Module to enable Cloud Asset API for HIPAA projects."""

import base64
import json
import logging
from typing import Any

from google.cloud import service_usage_v1

# Configure logging
logger = logging.getLogger(__name__)


def enable_cloud_asset_api(event: dict[str, Any], context: Any) -> None:
    """Triggered from a message on a Cloud Pub/Sub topic.

    Args:
         event (dict): Event payload.
         context (google.cloud.functions.Context): Metadata for the event.

    """
    _ = context  # Unused argument
    pubsub_message = base64.b64decode(event["data"]).decode("utf-8")
    log_entry = json.loads(pubsub_message)
    try:
        project_id = log_entry["protoPayload"]["request"]["project"]["projectId"]

        logger.info("Enabling Cloud Asset API for project: %s", project_id)

        client = service_usage_v1.ServiceUsageClient()
        service_name = f"projects/{project_id}/services/cloudasset.googleapis.com"

        request = service_usage_v1.EnableServiceRequest(name=service_name)

        try:
            operation = client.enable_service(request=request)
            logger.info("Waiting for operation %s to complete...", operation.name)
            response = operation.result()
            logger.info(
                "Successfully enabled Cloud Asset API for project %s: %s",
                project_id,
                response,
            )
        except Exception:
            logger.exception(
                "Error enabling Cloud Asset API for project %s",
                project_id,
            )
    except KeyError:
        logger.exception("Error parsing log entry: %s", log_entry)
