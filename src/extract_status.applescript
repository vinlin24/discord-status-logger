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

-- First click the avatar to open profile popout.
try
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

    popoutSuccess
on error number -2753
    display dialog "Failed to open profile popout!"
    error "Failed to open profile popout!"
end try

-- Give popout time to render.
delay 1

-- Try to get the custom status now that the popout is added to the DOM.
try
    tell application "Safari"
        set statusText to do JavaScript "
            const statusEl = document.querySelector('" & statusSelector & "');
            if (!statusEl) {
                throw new Error('Status element not found!');
            }
            statusEl.innerText;
        " in front document
    end tell

    return statusText
on error number -2753
    display dialog "Failed to extract status!"
    error "Failed to extract status!"
end try
