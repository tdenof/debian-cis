#!/bin/bash

# run-shellcheck
#
# CIS Debian Hardening
#

#
# 13.13 Check User Home Directory Ownership (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

# shellcheck disable=2034
HARDENING_LEVEL=2
# shellcheck disable=2034
DESCRIPTION="Check user home directory ownership."
EXCEPTIONS=""

ERRORS=0

# This function will be called if the script status is on enabled / audit mode
audit () {
    RESULT=$(awk -F: '{ print $1 ":" $3 ":" $6 }' /etc/passwd )
    for LINE in $RESULT; do
        debug "Working on $LINE"
        USER=$(awk -F: '{print $1}' <<< "$LINE")
        USERID=$(awk -F: '{print $2}' <<< "$LINE")
        DIR=$(awk -F: '{print $3}' <<< "$LINE")
        if [ "$USERID" -ge 500 ] && [ -d "$DIR" ] && [ "$USER" != "nfsnobody" ]; then
            OWNER=$(stat -L -c "%U" "$DIR")
            if [ "$OWNER" != "$USER" ]; then
                EXCEP_FOUND=0
                for excep in $EXCEPTIONS; do
                    if [ "$DIR:$USER:$OWNER" = "$excep" ]; then
                        ok "The home directory ($DIR) of user $USER is owned by $OWNER but is part of exceptions ($DIR:$USER:$OWNER)."
                        EXCEP_FOUND=1
                        break
                    fi
                done
                if [ "$EXCEP_FOUND" -eq 0 ]; then
                    crit "The home directory ($DIR) of user $USER is owned by $OWNER."
                    ERRORS=$((ERRORS+1))
                fi
            fi
        fi
    done

    if [ $ERRORS = 0 ]; then
        ok "All home directories have correct ownership"
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    awk -F: '{ print $1 " " $3 " " $6 }'  /etc/passwd | while read -r USER USERID DIR; do
        if [ "$USERID" -ge 500 ] && [ -d "$DIR" ] && [ "$USER" != "nfsnobody" ]; then
            OWNER=$(stat -L -c "%U" "$DIR")
            if [ "$OWNER" != "$USER" ]; then
                warn "The home directory ($DIR) of user $USER is owned by $OWNER."
                chown "$USER" "$DIR"
            fi
        fi
    done
}

# This function will create the config file for this check with default values
create_config() {
    cat <<EOF
status=audit
# Specify here exception for which owner of user's home directory is not the user
# "home:user:owner home2:user2:owner2"
EXCEPTIONS=""
EOF
}
# This function will check config parameters required
check_config() {
    :
}

# Source Root Dir Parameter
if [ -r /etc/default/cis-hardening ]; then
    . /etc/default/cis-hardening
fi
if [ -z "$CIS_ROOT_DIR" ]; then
     echo "There is no /etc/default/cis-hardening file nor cis-hardening directory in current environment."
     echo "Cannot source CIS_ROOT_DIR variable, aborting."
    exit 128
fi

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
if [ -r "$CIS_ROOT_DIR"/lib/main.sh ]; then
    # shellcheck source=/opt/debian-cis/lib/main.sh
    . "$CIS_ROOT_DIR"/lib/main.sh
else
    echo "Cannot find main.sh, have you correctly defined your root directory? Current value is $CIS_ROOT_DIR in /etc/default/cis-hardening"
    exit 128
fi