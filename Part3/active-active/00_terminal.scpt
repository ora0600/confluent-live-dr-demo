#!/usr/bin/osascript
on run argv
  set BASEDIR to item 1 of argv as string
  tell application "iTerm2"
    # open first terminal start consumer on cmcustomers
    tell current session of current tab of current window
        write text "cd " & BASEDIR
        write text "bash ./01-consumer_primary.sh"
        split horizontally with default profile
        split vertically with default profile
    end tell
    # open second terminal consumer to mirror-cmcustomers
    tell second session of current tab of current window
        write text "cd " & BASEDIR
        write text "bash ./01-consumer_secondary.sh"
    end tell
    # open third terminal and for the cold restore
    tell third session of current tab of current window
        write text "cd " & basedir
        write text "bash ./02-consumer_secondary_topic.sh"
        split vertically with default profile
    end tell
    # open forth terminal and for the cold restore
    tell fourth session of current tab of current window
        write text "cd " & basedir
        write text "bash ./02_consumer_primary_mirror.sh"
    end tell
end tell
end run