#!/usr/bin/osascript
-- Top-level script that delegates to (1) the status extraction script and then
-- (2) uploading the status as a CSV entry to our Google Drive source of truth.

try
    set statusOutput to do shell script "./extract_status.applescript"
on error errorMessage
    display dialog "Status extraction error: " & errorMessage
    error errorMessage
end try

-- The extraction script combines text and emoji as one newline-separated
-- string, so we re-split them to pass to our more expressive Python script.
set statusLines to paragraphs of statusOutput
set statusText to item 1 of statusLines
set statusEmoji to item 2 of statusLines

-- Escape quotes in case of special characters in the status.
set safeText to do shell script "printf '%q' " & quoted form of statusText

try
    do shell script "./log_status.py " & safeText & " '" & statusEmoji & "'"
on error errorMessage
    display dialog "Status upload error: " & errorMessage
    error errorMessage
end try
