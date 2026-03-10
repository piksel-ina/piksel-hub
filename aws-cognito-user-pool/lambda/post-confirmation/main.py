import os
import boto3
import logging
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    logger.info(f"Event: {json.dumps(event)}")

    trigger_source = event.get("triggerSource", "")
    logger.info(f"Trigger source: {trigger_source}")

    if not trigger_source.startswith("PostConfirmation_"):
        logger.info(f"Ignoring non-PostConfirmation trigger: {trigger_source}")
        return event

    cognito = boto3.client("cognito-idp")
    sns = boto3.client("sns")

    try:
        cognito.admin_add_user_to_group(
            UserPoolId=event["userPoolId"],
            Username=event["userName"],
            GroupName="pending_approval",
        )
        logger.info(f"Added user {event['userName']} to pending_approval group")
    except Exception as e:
        logger.error(f"Failed to add user to group: {e}")

    try:
        email = event["request"]["userAttributes"].get("email", "N/A")
        sns.publish(
            TopicArn=os.environ["SNS_TOPIC_ARN"],
            Subject="New User Pending Approval",
            Message=f"{event['userName']} is waiting for approval with this email: {email}",
        )
        logger.info(f"SNS notification sent for user: {event['userName']}")
    except Exception as e:
        logger.error(f"Failed to publish SNS: {e}")

    return event
