#!/usr/bin/env bash

SUDO_PASSWORD=

ssh_options()
{
    local REMOTE=${1}
    local MASTER_SOCKET="${REMOTE}.socket"
    local OPTIONS='-o ConnectTimeout=4'

    if [ -S "${MASTER_SOCKET}" ]
    then
        OPTIONS="${OPTIONS} -o ControlPath='${MASTER_SOCKET}'"
    else
        OPTIONS="${OPTIONS} -M -o ControlPath='${MASTER_SOCKET}' -o ControlPersist=yes"
    fi

    echo "${OPTIONS}"
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
    local COMMAND=${2}
    local OPTIONS=$(ssh_options "${REMOTE}")

    # Either provide COMMAND as function argument or from stdin
    if [ -z "${COMMAND}" ]
    then
        COMMAND=$(cat)
    fi

    ssh -T ${OPTIONS} "${REMOTE}" "${COMMAND}"
}

transfer()
{
    local REMOTE=${1}
    local LOCAL_FILE=${2}
    local REMOTE_FILE=${3}
    local OPTIONS=$(ssh_options "${REMOTE}")

    scp ${OPTIONS} "${LOCAL_FILE}" "${REMOTE}:${REMOTE_FILE}" 
}

ask_for_sudo_password()
{
    read -p 'sudo password required: ' -s SUDO_PASSWORD
}

