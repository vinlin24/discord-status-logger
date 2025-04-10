#!/usr/bin/osascript
-- Top-level script that delegates to (1) the status extraction script and then
-- (2) uploading the status as a CSV entry to our Google Drive source of truth.

-- Dynamically calculate paths of the other scripts based on path of currently
-- running AppleScript app (independence from CWD).
set thisScriptPath to POSIX path of (path to me)
set srcDirectory to do shell script "dirname " & quoted form of thisScriptPath
set uploadScriptPath to srcDirectory & "/log_status.py"
set extractScriptPath to srcDirectory & "/extract_status.applescript"

-- Make extracting from the Discord website opt-in (since it's kind of buggy,
-- not because of AppleScript but rather because Discord sometimes logs me out
-- and/or resets the status when I do log in). By default, prompt for the status
-- and then proceed to upload.
set extractDiscord to display dialog "Extract automatically from Discord?" Â
    buttons {"Yes", "No"} default button "No"

if button returned of extractDiscord is "Yes" then
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

else
    set statusText to text returned of (display dialog Â
        "Text status taken from clipboard:" default answer the clipboard)

    set statusEmoji to text returned of (display dialog Â
        "Paste or type an emoji:" default answer "")
end if

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

display dialog "Custom status uploaded successfully!" Â
    & "\nText: " & statusText & "\nEmoji: " & statusEmoji
