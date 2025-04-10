#!/usr/bin/osascript
-- Script to extract the Discord status text from the logged in landing page.
-- This involves clicking on the avatar region in the bottom left to open the
-- profile popout, then getting the text from the status field within it.

-- CSS selectors obtained from Web Inspector. Anticipate frequent change.
set avatarSelector to "#app-mount div.avatarWrapper__37e49"
set statusSelector to "#popout_51 > div > div > div > div > div > header > div.container_ab8609.biteSize_ab8609.editable_ab8609 > div.outer_ab8609.biteSize_ab8609 > span > div > div"
set emojiSelector to "#popout_51 > div > div > div > div > div > header > div.container_ab8609.biteSize_ab8609.editable_ab8609 > div.outer_ab8609.biteSize_ab8609 > span > div > img"

tell application "Safari"
    -- Steal focus. Having it run in the background is cool and all but that may
    -- make it hard to see why something goes wrong.
    activate
    open location "https://discord.com/channels/@me"
end tell

-- Wait for the Discord landing page to load.
delay 4

-- Find the index of the newly opened Discord tab so we can close it later.
on closeDiscordTab(tabIndex)
    if tabIndex is not 0 then
        tell application "Safari"
            try
                close tab tabIndex of front window
            end try
        end tell
    end if
end closeDiscordTab

set discordTabIndex to 0
tell application "Safari"
    set tabList to tabs of front window
    repeat with i from 1 to count of tabList
        if URL of item i of tabList contains "discord.com/login" then
            closeDiscordTab(i)
            display dialog "Stopped by login prompt!"
            error "Stopped by login prompt!"
        end if
        if URL of item i of tabList contains "discord.com/channels/@me" then
            set discordTabIndex to i
            exit repeat
        end if
    end repeat
end tell

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
set statusText to ""
tell application "Safari"
    set extractedStatusText to do JavaScript "
        const statusEl = document.querySelector('" & statusSelector & "');
        statusEl ? statusEl.innerText : '';
    " in front document
    try
        copy extractedStatusText to statusText
    end try
end tell

set statusEmoji to ""
tell application "Safari"
    set extractedStatusEmoji to do JavaScript "
        const emojiEl = document.querySelector('" & emojiSelector & "');
        emojiEl ? emojiEl.getAttribute('data-name') : '';
    " in front document
    try
        copy extractedStatusEmoji to statusEmoji
    end try
end tell

-- I wouldn't have an empty status. It's more likely there was an error.
if statusText is "" and statusEmoji is "" then
    closeDiscordTab(discordTabIndex)
    display dialog "Failed to extract status!"
    error "Failed to extract status!"
end if

closeDiscordTab(discordTabIndex)
return statusText & "\n" & statusEmoji
