import json
import logging
import os
import uuid
from datetime import datetime, timezone
from io import BytesIO

import boto3
from PIL import Image

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")

PROCESSED_BUCKET = os.environ["PROCESSED_BUCKET"]
METADATA_TABLE = os.environ["METADATA_TABLE"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
THUMBNAIL_SIZE = (800, 800)


def lambda_handler(event, context):
    """Entry point invoked asynchronously by an S3 ObjectCreated event."""
    table = dynamodb.Table(METADATA_TABLE)

    for record in event["Records"]:
        source_bucket = record["s3"]["bucket"]["name"]
        source_key = record["s3"]["object"]["key"]
        image_id = str(uuid.uuid4())

        logger.info(json.dumps({
            "event": "processing_start",
            "image_id": image_id,
            "source_key": source_key,
        }))

        try:
            raw_bytes = _download(source_bucket, source_key)
            resized_bytes, metadata = _resize_and_extract(raw_bytes)
            processed_key = f"processed/{image_id}.jpg"

            s3.put_object(
                Bucket=PROCESSED_BUCKET,
                Key=processed_key,
                Body=resized_bytes,
                ContentType="image/jpeg",
            )

            table.put_item(Item={
                "image_id": image_id,
                "source_key": source_key,
                "processed_key": processed_key,
                "width": metadata["width"],
                "height": metadata["height"],
                "format": metadata["format"],
                "size_bytes": len(resized_bytes),
                "processed_at": datetime.now(timezone.utc).isoformat(),
            })

            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=json.dumps({
                    "status": "done",
                    "image_id": image_id,
                    "processed_key": processed_key,
                }),
            )

            logger.info(json.dumps({
                "event": "processing_success",
                "image_id": image_id,
            }))

        except Exception:
            # Re-raise so Lambda's built-in async retry policy kicks in;
            # after retries are exhausted the event lands in the DLQ.
            logger.exception(json.dumps({
                "event": "processing_failed",
                "image_id": image_id,
                "source_key": source_key,
            }))
            raise


def _download(bucket, key):
    response = s3.get_object(Bucket=bucket, Key=key)
    return response["Body"].read()


def _resize_and_extract(raw_bytes):
    image = Image.open(BytesIO(raw_bytes))
    original_format = image.format or "JPEG"

    image.thumbnail(THUMBNAIL_SIZE)

    output = BytesIO()
    image.convert("RGB").save(output, format="JPEG", quality=85)

    metadata = {
        "width": image.width,
        "height": image.height,
        "format": original_format,
    }
    return output.getvalue(), metadata
