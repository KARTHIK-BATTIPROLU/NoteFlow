import os
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError
from typing import Optional, Dict, Any

R2_ACCOUNT_ID = os.environ.get("R2_ACCOUNT_ID")
R2_ENDPOINT = os.environ.get("R2_ENDPOINT")
R2_ACCESS_KEY_ID = os.environ.get("R2_ACCESS_KEY_ID")
R2_SECRET_ACCESS_KEY = os.environ.get("R2_SECRET_ACCESS_KEY")
R2_BUCKET = os.environ.get("R2_BUCKET")


def get_s3_client():
    """Return a boto3 S3 client configured for Cloudflare R2."""
    endpoint = R2_ENDPOINT
    if not endpoint and R2_ACCOUNT_ID:
        endpoint = f"https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
    
    if not endpoint or not R2_ACCESS_KEY_ID or not R2_SECRET_ACCESS_KEY or not R2_BUCKET:
        raise RuntimeError(
            "Missing Cloudflare R2 environment variables. "
            "Please ensure R2_ENDPOINT (or R2_ACCOUNT_ID), R2_ACCESS_KEY_ID, "
            "R2_SECRET_ACCESS_KEY, and R2_BUCKET are set."
        )

    return boto3.client(
        "s3",
        endpoint_url=endpoint,
        aws_access_key_id=R2_ACCESS_KEY_ID,
        aws_secret_access_key=R2_SECRET_ACCESS_KEY,
        config=Config(signature_version="s3v4"),
        region_name="auto"
    )


def presign_put(key: str, content_type: str, expires: int = 300) -> str:
    """Generate a presigned URL for direct HTTP PUT upload to R2."""
    s3 = get_s3_client()
    url = s3.generate_presigned_url(
        ClientMethod="put_object",
        Params={
            "Bucket": R2_BUCKET,
            "Key": key,
            "ContentType": content_type,
        },
        ExpiresIn=expires,
    )
    return url


def presign_get(key: str, filename: str, expires: int = 300) -> str:
    """Generate a presigned URL for direct HTTP GET download from R2."""
    s3 = get_s3_client()
    disposition = f'attachment; filename="{filename}"'
    url = s3.generate_presigned_url(
        ClientMethod="get_object",
        Params={
            "Bucket": R2_BUCKET,
            "Key": key,
            "ResponseContentDisposition": disposition,
        },
        ExpiresIn=expires,
    )
    return url


def head_object(key: str) -> Optional[Dict[str, Any]]:
    """Fetch object metadata from R2, or return None if object does not exist."""
    s3 = get_s3_client()
    try:
        response = s3.head_object(Bucket=R2_BUCKET, Key=key)
        return response
    except ClientError as e:
        if e.response.get("Error", {}).get("Code") in ("404", "NoSuchKey", "NotFound"):
            return None
        raise e


def delete_object(key: str) -> bool:
    """Delete an object from R2."""
    s3 = get_s3_client()
    try:
        s3.delete_object(Bucket=R2_BUCKET, Key=key)
        return True
    except ClientError:
        return False


def get_object_range(key: str, bytes_range: str = "bytes=0-7") -> Optional[bytes]:
    """Fetch a byte range of an object from R2 for header/magic-byte validation."""
    s3 = get_s3_client()
    try:
        response = s3.get_object(Bucket=R2_BUCKET, Key=key, Range=bytes_range)
        return response["Body"].read()
    except ClientError:
        return None
