import base64
from datetime import datetime
import os
from urllib.parse import urlparse
import boto3
from botocore.exceptions import NoCredentialsError
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from tempfile import mkdtemp
import yaml

CONFIG = os.environ.get("CONFIG")
BUCKET_ID = os.environ.get('BUCKET_ID')

s3 = boto3.client('s3')


def handler(event, context):
    if not CONFIG or not BUCKET_ID:
        # TODO: send to SNS
        print("Environment variables not set")
        raise

    options = webdriver.ChromeOptions()
    options.binary_location = '/opt/chrome/chrome'
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1280x1696")
    options.add_argument("--single-process")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-dev-tools")
    options.add_argument("--no-zygote")
    options.add_argument(f"--user-data-dir={mkdtemp()}")
    options.add_argument(f"--data-path={mkdtemp()}")
    options.add_argument(f"--disk-cache-dir={mkdtemp()}")
    options.add_argument("--remote-debugging-port=9222")
    service = Service(executable_path="/opt/chromedriver")
    chrome = webdriver.Chrome(service=service, options=options)

    decoded_config = yaml.safe_load(base64.b64decode(CONFIG))
    for page in decoded_config['pages']:
        chrome.get(page['url'])
        chrome.get_screenshot_as_file("/tmp/temp_screenshot.png")
        store_in_s3(page['url'])

    chrome.close()
    chrome.quit()

    response = {
        "statusCode": 200,
        "body": "Selenium Headless Chrome Initialized"
    }

    return response


def store_in_s3(url):
    try:
        s3.upload_file("/tmp/temp_screenshot.png", BUCKET_ID, find_object_path(url))
        print("Upload Successful", url)
        return url
    except FileNotFoundError:
        # TODO: send to SNS
        print("File not found")
        return None
    except NoCredentialsError:
        # TODO: send to SNS
        print("Credentials")
        return None


def find_object_path(url):
    now = datetime.utcnow()
    parsed_url = urlparse(url)
    return f"{parsed_url.netloc}{parsed_url.path}/{now.year}/{now.month}/{now.day}/{now.hour}/{now.minute}"
