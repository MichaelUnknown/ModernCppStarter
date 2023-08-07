#!/bin/bash
# arg $1: service executable

set -e
set -x
set -u

# "pseudo" main function to provide top-down sequence, called from last line
main() {
    # start the agent
    ${1} &
    thePID=$!
    interface=http://127.0.0.1:3080/hello

    trap cleanup EXIT

    sleep 1  # delay, be sure the service is ready

    curl ${interface}?
    curl ${interface}?language=
    curl ${interface}?language='bla'
    curl ${interface}?language='en'
    curl ${interface}?language='de'
    curl ${interface}?language='fr'

    echo "test done, send SIGHUP"
    echo cleanup OK
}

cleanup() {
    kill -s HUP %% && wait
    echo cleanup OK
}

main "$@"
