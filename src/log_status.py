#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Call the Google Apps Script to add an entry to the status log."""

import argparse
import csv
import http.client
import io
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import NoReturn, TypedDict

SCRIPT_NAME = Path(sys.argv[0]).name
API_SECRET_PATH = Path(__file__).parent.parent / "secret.txt"
APP_URL_TEMPLATE = "https://script.google.com/macros/s/{deployment_id}/exec"

CsvRow = tuple[str, str, str, str]


class PostData(TypedDict):
    secret: str
    line: str


parser = argparse.ArgumentParser(prog=SCRIPT_NAME)
parser.add_argument("status")
parser.add_argument("emoji", nargs="?", default="")


def exit_with_error(message: str) -> NoReturn:
    print(f"{SCRIPT_NAME}: {message}", file=sys.stderr)
    sys.exit(1)


def load_api_secret() -> str:
    if not API_SECRET_PATH.exists():
        exit_with_error(f"{API_SECRET_PATH} (API secret) file not found")

    content = API_SECRET_PATH.read_text(encoding="utf-8")
    return content.strip()


def parse_deployment_id() -> str:
    # pylint: disable=subprocess-run-check
    process = subprocess.run(
        ["clasp", "list-deployments"],
        capture_output=True,
        text=True,
    )

    if process.returncode != 0:
        exit_with_error(f"clasp: {process.stderr}")

    last_line = process.stdout.splitlines()[-1]
    _, deployment_id, *_ = last_line.split()
    return deployment_id


def format_csv_line(status: str, emoji: str) -> str:
    now = datetime.now()
    date_string = now.date().isoformat()
    time_string = now.time().isoformat()

    row: CsvRow = (date_string, time_string, emoji, status)

    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(row)
    raw_csv_line = buffer.getvalue().strip()

    return raw_csv_line


def call_apps_script(deployment_id: str, data: PostData) -> str:
    # NOTE: Encode data for application/x-www-form-urlencoded.
    encoded_data = urllib.parse.urlencode(data).encode("utf-8")
    endpoint = APP_URL_TEMPLATE.format(deployment_id=deployment_id)

    request = urllib.request.Request(
        endpoint,
        data=encoded_data,
        method="POST",
    )

    response: http.client.HTTPResponse
    try:
        with urllib.request.urlopen(request) as response:
            return response.read().decode()
    except urllib.error.HTTPError as error:
        exit_with_error(f"HTTP {error.code} Error: {error.reason}")
    except urllib.error.URLError as error:
        exit_with_error(f"URL Error: {error.reason}")


def process_apps_script_response(response_text: str) -> None:
    # Responses and their meanings defined in Apps Script.
    if response_text != "OK":
        exit_with_error(f"Apps Script: {response_text}")


def main() -> None:
    args = parser.parse_args()
    status: str = args.status
    emoji: str = args.emoji

    api_secret = load_api_secret()
    deployment_id = parse_deployment_id()
    csv_line = format_csv_line(status, emoji)

    response_text = call_apps_script(deployment_id, {
        "line": csv_line,
        "secret": api_secret,
    })
    process_apps_script_response(response_text)


if __name__ == "__main__":
    main()
