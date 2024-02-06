#!/usr/bin/osascript
on run argv
  set BASEDIR to item 1 of argv as string
  tell application "iTerm2"
    # open first terminal start consumer on cmorders
    tell current session of current tab of current window
        write text "cd " & BASEDIR
        write text "bash ./01-consumer.sh"
        split horizontally with default profile
        split vertically with default profile
    end tell
    # open second terminal producer to cmorers
    tell second session of current tab of current window
        write text "cd " & BASEDIR
        write text "bash ./02-producer.sh"
    end tell
    # open third terminal and for the cold restore
    tell third session of current tab of current window
        write text "cd " & basedir
        write text "cd ../Part2/cold-restore"
    end tell
  end tell
end run