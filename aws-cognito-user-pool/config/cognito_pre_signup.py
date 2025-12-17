import json
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
  """
  Pre Sign-up Lambda trigger to validate custom attributes for PIKSEL
  """
  try:
      logger.info(f"Pre-signup event received: {json.dumps(event, default=str)}")
      
      user_attributes = event['request']['userAttributes']
      email = user_attributes.get('email', '')
      
      logger.info(f"Processing signup for user: {email}")
      
      # Validate institution
      institution = user_attributes.get('custom:institution', '').strip()
      if not institution:
          logger.warning(f"Institution validation failed for {email} - empty or missing")
          raise Exception("Institution is required for registration. Please provide your institution name.")
      
      if len(institution) < 1 or len(institution) > 256:
          logger.warning(f"Institution validation failed for {email} - invalid length: {len(institution)}")
          raise Exception("Institution name must be between 1 and 256 characters.")
      
      # Validate phone
      phone = user_attributes.get('custom:phone', '').strip()
      if not phone:
          logger.warning(f"Phone validation failed for {email} - empty or missing")
          raise Exception("Phone number is required for registration. Please provide your phone number.")
      
      if len(phone) < 8 or len(phone) > 15:
          logger.warning(f"Phone validation failed for {email} - invalid length: {len(phone)}")
          raise Exception("Phone number must be between 8 and 15 characters.")
      
      # Additional validation (optional)
      if not phone.replace('+', '').replace('-', '').replace(' ', '').replace('(', '').replace(')', '').isdigit():
          logger.warning(f"Phone validation failed for {email} - invalid format")
          raise Exception("Phone number contains invalid characters. Please use only numbers, +, -, (), and spaces.")
      
      logger.info(f"Validation passed for user {email} - Institution: {institution}, Phone: {phone}")
      return event
      
  except Exception as e:
      logger.error(f"Validation error: {str(e)}")
      raise e