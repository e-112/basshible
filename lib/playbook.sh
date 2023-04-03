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

transfer_file()
{
    local LOCAL_FILE=${1}
    local REMOTE_FILE=${2}

    transfer "${CURRENT_REMOTE}" "${LOCAL_FILE}" "${REMOTE_FILE}"
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
set +o history
${TOOLBOX}
${REMOTE_ENV}
${SOURCE}
${@}
EOF

}

run_remote_as()
{
    # Keeping it simple for now.
    # We require that the connection user is a sudoer.
    
    local REMOTE_USER=${1}
    shift

    local TOOLBOX="$(declare -f register_var)"
    local REMOTE_ENV=

    # Inject shared environment variables
    if [ -s "${CURRENT_ENV_FILE}" ]
    then
        REMOTE_ENV="$(<${CURRENT_ENV_FILE})"
    fi

    # Inject the source of our remote command
    local SOURCE="$(declare -f ${1})"
    
    # First hackish draft
    # 1. Create a remote temp file 
    local TMP_REMOTE_SCRIPT=$(connect "${CURRENT_REMOTE}" <<<"mktemp")

    # 2. Populate it with our content and make it executable
   connect "${CURRENT_REMOTE}" <<EOF
cat >${TMP_REMOTE_SCRIPT} <<"INNER_EOF"
#!/usr/bin/env bash
set +o history
${TOOLBOX}
${REMOTE_ENV}
${SOURCE}
${@}
INNER_EOF

chmod a+x "${TMP_REMOTE_SCRIPT}"
EOF
   
   # 3. Execute it with different user, then drop it
   connect "${CURRENT_REMOTE}" <<EOF
set +o history
echo -n "${SUDO_PASSWORD}" | sudo -S -u "${REMOTE_USER}" "${TMP_REMOTE_SCRIPT}"
rm "${TMP_REMOTE_SCRIPT}"
EOF

}

requires_elevation()
{
    local PLAYBOOK_FILE=${1}

    # Returns 0 if at least a match has been found
    grep -q -E '^[[:space:]]*run_remote_as' "${PLAYBOOK_FILE}"
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

