import os
from io import BytesIO

import boto3
import pytest
from moto import mock_aws
from PIL import Image

os.environ["PROCESSED_BUCKET"] = "test-processed"
os.environ["METADATA_TABLE"] = "test-metadata"
os.environ["SNS_TOPIC_ARN"] = "arn:aws:sns:us-east-1:123456789012:test-topic"

from src.processor import handler  # noqa: E402


def _sample_jpeg_bytes():
    img = Image.new("RGB", (1200, 900), color="red")
    buf = BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


@mock_aws
def test_processing_success_writes_resized_image_and_metadata():
    s3 = boto3.client("s3", region_name="us-east-1")
    s3.create_bucket(Bucket="test-raw")
    s3.create_bucket(Bucket="test-processed")
    s3.put_object(Bucket="test-raw", Key="incoming/photo.jpg", Body=_sample_jpeg_bytes())

    dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
    dynamodb.create_table(
        TableName="test-metadata",
        KeySchema=[{"AttributeName": "image_id", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "image_id", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )

    sns = boto3.client("sns", region_name="us-east-1")
    sns.create_topic(Name="test-topic")

    event = {
        "Records": [{
            "s3": {
                "bucket": {"name": "test-raw"},
                "object": {"key": "incoming/photo.jpg"},
            }
        }]
    }

    handler.lambda_handler(event, context=None)

    processed_objects = s3.list_objects_v2(Bucket="test-processed").get("Contents", [])
    assert len(processed_objects) == 1

    table = dynamodb.Table("test-metadata")
    items = table.scan()["Items"]
    assert len(items) == 1
    assert items[0]["width"] <= 800
    assert items[0]["format"] == "JPEG"


@mock_aws
def test_missing_source_object_raises_and_is_not_swallowed():
    boto3.client("s3", region_name="us-east-1").create_bucket(Bucket="test-raw")
    event = {"Records": [{"s3": {"bucket": {"name": "test-raw"}, "object": {"key": "missing.jpg"}}}]}

    with pytest.raises(Exception):
        handler.lambda_handler(event, context=None)
