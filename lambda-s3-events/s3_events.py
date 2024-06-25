import json
import boto3
import os
import pandas as pd
import logging

# Initialize the S3 client
s3 = boto3.client('s3')

# Setup logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    Lambda function to process S3 events received through SQS,
    move files from source directory to target directory within the same bucket,
    and log the operations.
    """
    logger.info("Received event: " + json.dumps(event, indent=2))

    # Retrieve source and target directories from environment variables
    source_directory = os.getenv('SOURCE_DIR')
    target_directory = os.getenv('TARGET_DIR')

    for record in event['Records']:
        try:
            # Extract the S3 event information from the SQS message body
            message = json.loads(record['body'])
            s3_event = message['Records'][0]

            # Get the bucket name and the source key from the S3 event
            bucket_name = s3_event['s3']['bucket']['name']
            source_key = s3_event['s3']['object']['key']

            # Create a pandas DataFrame for logging purposes
            df = pd.DataFrame({
                'Bucket': [bucket_name],
                'SourceKey': [source_key],
            })
            logger.info("Printing pandas DataFrame:\n")
            logger.info(df.to_string(index=False))

            # Determine the destination key by replacing the source directory with the target directory
            destination_key = source_key.replace(source_directory, target_directory, 1)

            # Copy the object to the target directory
            copy_source = {'Bucket': bucket_name, 'Key': source_key}
            s3.copy_object(CopySource=copy_source, Bucket=bucket_name, Key=destination_key)
            # Delete the original object
            s3.delete_object(Bucket=bucket_name, Key=source_key)

            logger.info(f"Moved {source_key} to {destination_key}")
        except KeyError as e:
            logger.error(f"KeyError: {e}")
        except Exception as e:
            logger.error(f"Exception: {e}")

    return {
        'statusCode': 200,
        'body': json.dumps('File moved successfully')
    }
