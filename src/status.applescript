#!/usr/bin/osascript
-- Top-level script that delegates to (1) the status extraction script and then
-- (2) uploading the status as a CSV entry to our Google Drive source of truth.

set statusText to do shell script "./extract_status.applescript"

-- Escape quotes in case of emojis or special chars.
set safeStatusText to do shell script "printf '%q' " & quoted form of statusText

do shell script "./log_status.py " & safeStatusText
