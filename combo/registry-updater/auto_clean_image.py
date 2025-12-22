#!/usr/bin/env python3

# crontab 
# 0 2 1,15 * * /mnt/scripts/auto_clean_image.py >> /var/log/auto_clean_image.log 2>&1

import logging, sys, re, json
import base64
from urllib import request, parse

REGISTRY_URL = "http://xx.yy.info:5000"
REPO = "ff/ffgo"
KEEP = 10

USE_BASIC = True
USERNAME = "alice"
PASSWORD = "alice"

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

def get_basic_header():
    creds = f"{USERNAME}:{PASSWORD}".encode()
    token = base64.b64encode(creds).decode()
    return {"Authorization": f"Basic {token}"}

def make_request(method, url, headers=None):
    req = request.Request(url, method=method, headers=headers or {})
    return request.urlopen(req)

def get_auth_header():
    if USE_BASIC:
        return get_basic_header()
    else:
        return {}

def http_request(method, url):
    hdr = {"Accept": "application/vnd.docker.distribution.manifest.v2+json"}
    hdr.update(get_auth_header())
    req = request.Request(url, method=method, headers=hdr)
    return request.urlopen(req)

def get_tags():
    url = f"{REGISTRY_URL}/v2/{REPO}/tags/list"
    with http_request("GET", url) as resp:
        return json.load(resp).get("tags", [])

def filter_versions(tags):
    return [t for t in tags if re.match(r'^[0-9]+(?:\.[0-9]+)*$', t)]

def parse_version(v):
    return tuple(map(int, v.split('.')))

def get_digest(tag):
    url = f"{REGISTRY_URL}/v2/{REPO}/manifests/{tag}"
    try:
        resp = http_request("HEAD", url)
        return resp.getheader("Docker-Content-Digest")
    except Exception as e:
        print(f"get digest failed ({tag}) : {e}", file=sys.stderr)
        return None

def delete_digest(digest):
    url = f"{REGISTRY_URL}/v2/{REPO}/manifests/{parse.quote(digest, safe='')}"
    try:
        resp = http_request("DELETE", url)
        return resp.status == 202 or resp.status == 200
    except Exception as e:
        print(f"failed to delete ({digest}) : {e}", file=sys.stderr)
        return False

def main():
    tags = get_tags()

    version_tags = filter_versions(tags)
    version_tags_sorted = sorted(version_tags, key=parse_version)
    keep = version_tags_sorted[-KEEP:]
    to_delete = [t for t in version_tags_sorted if t not in keep]

    logger.info("To delete: %s", to_delete)

    for tag in to_delete:
        digest = get_digest(tag)
        if not digest:
            continue
        delete_digest(digest)

if __name__ == "__main__":
    main()
