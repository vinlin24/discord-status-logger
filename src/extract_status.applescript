#!/usr/bin/osascript
-- Script to extract the Discord status text from the logged in landing page.
-- This involves clicking on the avatar region in the bottom left to open the
-- profile popout, then getting the text from the status field within it.

-- CSS selectors obtained from Web Inspector. Anticipate frequent change.
set avatarSelector to "#app-mount div.avatarWrapper__37e49"
set statusSelector to "#popout_51 > div > div > div > div > div > header > div.container_ab8609.biteSize_ab8609.editable_ab8609 > div.outer_ab8609.biteSize_ab8609 > span > div > div"

tell application "Safari"
    -- NOTE: No `activate` here so the script doesn't steal focus.
    open location "https://discord.com/channels/@me"
end tell

-- Wait for the Discord landing page to load.
delay 4

-- Find the index of the newly opened Discord tab so we can close it later.
set discordTabIndex to 0
tell application "Safari"
    set tabList to tabs of front window
    repeat with i from 1 to count of tabList
        if URL of item i of tabList contains "discord.com/channels/@me" then
            set discordTabIndex to i
            exit repeat
        end if
    end repeat
end tell

on closeDiscordTab(tabIndex)
    if tabIndex is not 0 then
        tell application "Safari"
            try
                close tab tabIndex of front window
            end try
        end tell
    end if
end closeDiscordTab

-- First click the avatar to open profile popout.
tell application "Safari"
    set popoutSuccess to do JavaScript "
        const avatarEl = document.querySelector('" & avatarSelector & "');
        if (!avatarEl) {
            throw new Error('Profile popout not found!');
        }
        avatarEl.click();
        true;
    " in front document
end tell
try
    popoutSuccess
on error number -2753
    closeDiscordTab(discordTabIndex)
    display dialog "Failed to open profile popout!"
    error "Failed to open profile popout!"
end try

-- Give the popout time to render.
delay 1

-- Try to get the custom status now that the popout is added to the DOM.
tell application "Safari"
    set statusText to do JavaScript "
        const statusEl = document.querySelector('" & statusSelector & "');
        if (!statusEl) {
            throw new Error('Status element not found!');
        }
        statusEl.innerText;
    " in front document
end tell
try
    statusText
on error number -2753
    closeDiscordTab(discordTabIndex)
    display dialog "Failed to extract status!"
    error "Failed to extract status!"
end try

closeDiscordTab(discordTabIndex)
return statusText
