import json
import boto3
import os
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Users')  # Replace with your actual table name

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))  # Helpful for debugging in CloudWatch

    # Detect HTTP method based on source (Lambda Test or API Gateway)
    method = event.get('httpMethod') or event.get('requestContext', {}).get('http', {}).get('method')
    
    if method == 'GET':
        return get_users(event)
    elif method == 'POST':
        body = json.loads(event.get('body', '{}'))
        return create_user(body)
    elif method == 'PUT':
        body = json.loads(event.get('body', '{}'))
        return update_user(body)
    elif method == 'DELETE':
        params = event.get('queryStringParameters', {})
        return delete_user(params.get('email'))
    else:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Unsupported method'})
        }

def create_user(body):
    try:
        required_fields = ["email", "name", "dob", "gender", "weight", "height"]
        
        # Check if all required fields are present in the request body
        if not all(field in body for field in required_fields):
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Missing required user fields'})
            }

        # Insert the user data into the DynamoDB table
        table.put_item(Item=body)
        
        return {
            'statusCode': 201,
            'body': json.dumps({'message': 'User created successfully'})
        }
    except Exception as e:
        print("Error creating user:", str(e))
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def get_users(event):
    try:
        email = event.get("queryStringParameters", {}).get("email")
        
        # If email is not provided, return error
        if not email:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Email is required'})
            }
        
        # Fetch user from DynamoDB based on email
        response = table.get_item(Key={"email": email})
        
        if "Item" not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'User not found'})
            }
        
        # Return the found user data
        return {
            'statusCode': 200,
            'body': json.dumps(response['Item'])
        }
    except Exception as e:
        print("Error fetching user:", str(e))
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def update_user(body):
    try:
        email = body.get("email")
        
        # Ensure email is provided for update
        if not email:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Email is required'})
            }
        
        # Prepare update expression and attribute values
        update_expression = "SET "
        expression_values = {}
        for key in ["name", "dob", "gender", "weight", "height"]:
            if key in body:
                update_expression += f"{key} = :{key}, "
                expression_values[f":{key}"] = body[key]

        # If no fields are provided to update, return an error
        if not expression_values:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Nothing to update'})
            }

        update_expression = update_expression.rstrip(", ")

        # Update the user in DynamoDB
        table.update_item(
            Key={"email": email},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values
        )

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'User updated successfully'})
        }
    except Exception as e:
        print("Error updating user:", str(e))
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def delete_user(email):
    try:
        if not email:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Email is required'})
            }

        # Delete the user from DynamoDB
        table.delete_item(Key={"email": email})

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'User deleted successfully'})
        }
    except Exception as e:
        print("Error deleting user:", str(e))
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
