#!/usr/bin/env python3
"""Plan or delete old numeric registry tags without deleting shared manifests."""

import argparse
import base64
import json
import logging
import os
import re
from urllib import parse, request

LOG = logging.getLogger(__name__)
ACCEPT = ", ".join(
    (
        "application/vnd.docker.distribution.manifest.v2+json",
        "application/vnd.docker.distribution.manifest.list.v2+json",
        "application/vnd.oci.image.manifest.v1+json",
        "application/vnd.oci.image.index.v1+json",
    )
)


class RegistryClient:
    def __init__(self, url, repository, username=None, password=None):
        self.url = url.rstrip("/")
        self.repository = repository
        self.headers = {"Accept": ACCEPT}
        if username is not None:
            credentials = base64.b64encode(f"{username}:{password}".encode()).decode()
            self.headers["Authorization"] = f"Basic {credentials}"

    def open(self, method, url):
        req = request.Request(url, method=method, headers=self.headers)
        return request.urlopen(req, timeout=10)

    def tags(self):
        url = f"{self.url}/v2/{self.repository}/tags/list"
        result = []
        visited = set()
        while url:
            if url in visited:
                raise ValueError(f"Registry pagination loop at {url}")
            visited.add(url)
            with self.open("GET", url) as response:
                result.extend(json.load(response).get("tags") or [])
                link = response.headers.get("Link", "")
            match = re.search(r'<([^>]+)>;\s*rel="?next"?', link)
            url = parse.urljoin(url, match.group(1)) if match else None
        return sorted(set(result))

    def digest(self, tag):
        url = f"{self.url}/v2/{self.repository}/manifests/{parse.quote(tag, safe='')}"
        with self.open("HEAD", url) as response:
            digest = response.headers.get("Docker-Content-Digest")
        if not digest:
            raise ValueError(f"No digest returned for tag {tag}")
        return digest

    def delete(self, digest):
        url = f"{self.url}/v2/{self.repository}/manifests/{parse.quote(digest, safe='')}"
        with self.open("DELETE", url) as response:
            if response.status != 202:
                raise RuntimeError(f"Delete {digest} returned HTTP {response.status}")


def version_key(tag):
    return tuple(int(part) for part in tag.split("."))


def plan_deletions(tags, keep, digest_for_tag):
    """Retain the newest numeric tags and every non-numeric tag."""
    versions = sorted(
        (tag for tag in tags if re.fullmatch(r"[0-9]+(?:\.[0-9]+)*", tag)),
        key=version_key,
    )
    obsolete = set(versions[:-keep])
    if not obsolete:
        return []

    # Resolve all aliases before deleting anything. An error aborts the whole run.
    digests = {tag: digest_for_tag(tag) for tag in tags}
    retained_digests = {digest for tag, digest in digests.items() if tag not in obsolete}
    return sorted({digests[tag] for tag in obsolete} - retained_digests)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default=os.getenv("REGISTRY_URL", "http://127.0.0.1:5000"))
    parser.add_argument("--repo", default=os.getenv("REGISTRY_REPO"), required=False)
    parser.add_argument("--keep", type=int, default=int(os.getenv("REGISTRY_KEEP", "10")))
    parser.add_argument("--apply", action="store_true", help="Actually delete manifests; default is dry-run")
    args = parser.parse_args(argv)
    if not args.repo:
        parser.error("--repo or REGISTRY_REPO is required")
    if args.keep < 1:
        parser.error("--keep must be at least 1")

    username = os.getenv("REGISTRY_USERNAME")
    password = os.getenv("REGISTRY_PASSWORD")
    if (username is None) != (password is None):
        parser.error("Set both REGISTRY_USERNAME and REGISTRY_PASSWORD, or neither")

    client = RegistryClient(args.url, args.repo, username, password)
    digests = plan_deletions(client.tags(), args.keep, client.digest)
    LOG.info("Manifest digests eligible for deletion: %s", digests)
    if not args.apply:
        LOG.info("Dry-run only. Pass --apply to delete.")
        return 0
    for digest in digests:
        client.delete(digest)
        LOG.info("Deleted %s", digest)
    return 0


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    raise SystemExit(main())
