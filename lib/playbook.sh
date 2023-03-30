#!/usr/bin/env bash

SOURCE_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

. "${SOURCE_DIR}/connection.sh"

unset SOURCE_DIR

register_var()
{
    local VAR_NAME=${1}
    local VAR_VALUE=${2}

    export ${VAR_NAME}="${VAR_VALUE}"
    echo "__playbook_register_var ${VAR_NAME}=\"${VAR_VALUE}\""
}

run_local()
{
    eval "${@}"
}

run_remote()
{
    # Inject toolbox command
    local TOOLBOX="$(declare -f register_var)"
    local REMOTE_ENV=

    # Inject shared environment variables
    if [ -s "${CURRENT_ENV_FILE}" ]
    then
        REMOTE_ENV="$(<${CURRENT_ENV_FILE})"
    fi

    # Inject the source of our remote command
    local SOURCE="$(declare -f ${1})"
    
    connect "${CURRENT_REMOTE}" <<EOF
${TOOLBOX}
${REMOTE_ENV}
${SOURCE}
${@}
EOF

}

run_playbook()
{
    local PLAYBOOK_FILE=${1}
    local HOST=${2}
    local ENV_FILE=${3}

    local PLAYBOOK_DIR=$(dirname "$(readlink -f "${PLAYBOOK_FILE}")")

    export CURRENT_REMOTE=${HOST}
    export CURRENT_ENV_FILE=${ENV_FILE}

    local TMP_FILE=$(mktemp)

    . "${PLAYBOOK_FILE}" |tee "${TMP_FILE}" |grep -v '^__playbook_register_var'

    # Filter out the variable registering output and transform them into export statements
    sed -n 's|^__playbook_register_var|export|p' "${TMP_FILE}" >> ${ENV_FILE}

    disconnect ${HOST}

    rm "${TMP_FILE}"
}

