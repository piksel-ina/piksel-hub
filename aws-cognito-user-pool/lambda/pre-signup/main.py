import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

cognito = boto3.client("cognito-idp")


def handler(event, context):
    email = event["request"]["userAttributes"].get("email")
    user_pool_id = event["userPoolId"]

    try:
        response = cognito.list_users(
            UserPoolId=user_pool_id,
            Filter=f'email = "{email}"',
        )

        for user in response["Users"]:
            status = user["UserStatus"]
            enabled = user["Enabled"]

            # Clean up disabled or unconfirmed duplicate
            if not enabled or status == "UNCONFIRMED":
                cognito.admin_delete_user(
                    UserPoolId=user_pool_id,
                    Username=user["Username"],
                )
                logger.info(f"Deleted stale user: {user['Username']}")

    except Exception as e:
        logger.error(f"Pre sign-up check failed: {e}")
        raise

    return event
