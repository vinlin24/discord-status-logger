#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Call the Google Apps Script to add an entry to the status log."""

import argparse
import csv
import io
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import NoReturn, TypedDict

SCRIPT_NAME = Path(sys.argv[0]).name
SECRETS_PATH = Path(__file__).parent.parent / ".env"
APP_URL_TEMPLATE = "https://script.google.com/macros/s/{deployment_id}/exec"


class Secrets(TypedDict):
    API_SECRET: str
    DEPLOYMENT_ID: str


class PostData(TypedDict):
    secret: str
    line: str


CsvRow = tuple[str, str, str, str]


parser = argparse.ArgumentParser(prog=SCRIPT_NAME)
parser.add_argument("status")
parser.add_argument("emoji", nargs="?", default="")


def exit_with_error(message: str) -> NoReturn:
    print(f"{SCRIPT_NAME}: {message}", file=sys.stderr)
    sys.exit(1)


def load_secrets() -> Secrets:
    if not SECRETS_PATH.exists():
        exit_with_error(f"{SECRETS_PATH} file not found")

    content = SECRETS_PATH.read_text(encoding="utf-8")

    pairs = dict[str, str]()
    for line in content.splitlines():
        line = line.strip()
        if line.startswith("#"):
            continue
        lhs, rhs = line.split("=")
        pairs[lhs.strip()] = rhs.strip().strip("'\"")

    return Secrets(**pairs)


def format_csv_line(status: str, emoji: str) -> str:
    now = datetime.now()
    date_string = now.date().isoformat()
    time_string = now.time().isoformat()

    row: CsvRow = (date_string, time_string, emoji, status)

    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(row)
    return buffer.getvalue().strip()


def call_apps_script(csv_line: str, secrets: Secrets) -> None:
    post_data: PostData = {
        "line": csv_line,
        "secret": secrets["API_SECRET"],
    }

    # NOTE: Encode data for application/x-www-form-urlencoded.
    encoded_data = urllib.parse.urlencode(post_data).encode("utf-8")

    endpoint = APP_URL_TEMPLATE.format(deployment_id=secrets["DEPLOYMENT_ID"])
    request = urllib.request.Request(
        endpoint,
        data=encoded_data,
        method="POST",
    )

    try:
        with urllib.request.urlopen(request) as response:
            response_text = response.read().decode()
    except urllib.error.HTTPError as error:
        exit_with_error(f"HTTP {error.code} Error: {error.reason}")
    except urllib.error.URLError as error:
        exit_with_error(f"URL Error: {error.reason}")

    if response_text != "OK":
        exit_with_error(f"Apps Script: {response_text}")


def main() -> None:
    args = parser.parse_args()
    status: str = args.status
    emoji: str = args.emoji

    secrets = load_secrets()
    csv_line = format_csv_line(status, emoji)
    call_apps_script(csv_line, secrets)


if __name__ == "__main__":
    main()
