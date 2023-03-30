#!/usr/bin/env bash

ssh_options()
{
    local REMOTE=${1}
    local MASTER_SOCKET="${REMOTE}.socket"

    if [ -S "${MASTER_SOCKET}" ]
    then
        echo "-o ControlPath='${MASTER_SOCKET}'"
    else
        echo "-M -o ControlPath='${MASTER_SOCKET}' -o ControlPersist=yes"
    fi
}

disconnect()
{
    local REMOTE=${1}
    local MASTER_SOCKET="${REMOTE}.socket"

    [ -S "${MASTER_SOCKET}" ] && rm "${MASTER_SOCKET}"
}

connect()
{
    local REMOTE=${1}
    local OPTIONS=$(ssh_options "${REMOTE}")

    ssh ${OPTIONS} "${REMOTE}" 
}
