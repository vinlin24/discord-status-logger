#!/usr/bin/osascript
-- Top-level script that delegates to (1) the status extraction script and then
-- (2) uploading the status as a CSV entry to our Google Drive source of truth.

-- Dynamically calculate paths of the other scripts based on path of currently
-- running AppleScript app (independence from CWD).
set thisScriptPath to POSIX path of (path to me)
set srcDirectory to do shell script "dirname " & quoted form of thisScriptPath
set uploadScriptPath to srcDirectory & "/log_status.py"
set extractScriptPath to srcDirectory & "/extract_status.applescript"

try
    set statusOutput to do shell script extractScriptPath
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
    -- .app shells use a minified default environment, so we need to manually
    -- restore PATH to include anything we need.
    do shell script "export PATH=/opt/homebrew/bin:$PATH; " Â
        & uploadScriptPath & " " & safeText & " '" & statusEmoji & "'"
on error errorMessage
    display dialog "Status upload error: " & errorMessage
    error errorMessage
end try

display dialog "Custom status extracted and uploaded successfully!"
