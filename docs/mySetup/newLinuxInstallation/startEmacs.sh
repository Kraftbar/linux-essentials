#!/bin/sh

echo "First arg: $1"
echo "Second arg: $2"
echo "Second arg: $3"
echo "Second arg: $4"
emacs_server_is_running(){
emacsclient -a false -e 't'
}


if emacs_server_is_running; then
    /usr/bin/emacsclient $1
else
    /usr/bin/emacs $1
fi
