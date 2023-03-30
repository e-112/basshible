#!/usr/bin/env bash

# pc_alias user=<> tags=<foo>,<bar>,<baz>
filter_hosts_by_tag()
{
    local INVENTORY=${1}
    local TAG=${2}

    # Ignore comment line beginning by '#'
    grep -v '^#' "${INVENTORY}" | \
    # Ignore empty lines
    grep -v -E '^[[:space:]]*$' |
    # Keep lines where this a tag=<something>,<other>
    grep -E ".*tags=[^[:space:]]*${TAG}(,|[[:space:]]|$)"
}

extract_value()
{
    local LINE=${1}
    local VALUE=${2}

    echo "${LINE}" | sed -E -n "s|.*${VALUE}=([^ ]*).*|\1|p"
}

extract_host_alias()
{
    local LINE=${1}

    echo "${LINE}" | cut -d' ' -f1
}

resolve_connection_string()
{
    local HOST_LINE=${1}

    local HOSTNAME=$(extract_value "${HOST_LINE}" host)
    local USER=$(extract_value "${HOST_LINE}" user)

    if [ -z "${HOSTNAME}" ]
    then
        # If no host=foo is provided, we take the host alias as hostname value
        HOSTNAME=$(extract_host_alias "${HOST_LINE}")
    fi

    if [[ -n ${USER} ]]
    then
        echo "${USER}@${HOSTNAME}"
    else
        echo ${HOSTNAME}
    fi
}

