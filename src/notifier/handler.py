import json
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

ses = boto3.client("ses")

NOTIFY_EMAIL_FROM = os.environ.get("NOTIFY_EMAIL_FROM", "no-reply@example.com")
NOTIFY_EMAIL_TO = os.environ.get("NOTIFY_EMAIL_TO", "you@example.com")


def lambda_handler(event, context):
    """Triggered by the processing-done SNS topic."""
    for record in event["Records"]:
        message = json.loads(record["Sns"]["Message"])
        image_id = message.get("image_id")
        processed_key = message.get("processed_key")

        logger.info(json.dumps({
            "event": "notify_start",
            "image_id": image_id,
        }))

        ses.send_email(
            Source=NOTIFY_EMAIL_FROM,
            Destination={"ToAddresses": [NOTIFY_EMAIL_TO]},
            Message={
                "Subject": {"Data": f"Image {image_id} processed"},
                "Body": {
                    "Text": {
                        "Data": f"Your image finished processing.\n\nKey: {processed_key}"
                    }
                },
            },
        )

        logger.info(json.dumps({
            "event": "notify_success",
            "image_id": image_id,
        }))
