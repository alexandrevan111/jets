import pprint
import json
import sys

def response(message, status_code):
    ERROR_RIGHT_HERE
    return {
        'statusCode': str(status_code),
        'body': json.dumps(message),
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
            },
        }

def handle(event, context):
    # TODO: figure out why this does not print out to stderr with python 3
    # print("BooksController#show", file=sys.stderr)
    # print(pprint.pformat(event), file=sys.stderr))

    try:
        return response({'message': 'Big Thumbs up'}, 200)
    except Exception as e:
        return response({'message': e.message}, 400)

if __name__ == '__main__':
    print(handle({"test": "1"}, {}))