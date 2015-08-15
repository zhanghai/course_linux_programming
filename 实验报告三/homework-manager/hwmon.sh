#!/bin/bash
#
# hwmon.sh: Script for homework manager.
#
# Copyright (c) 2014 Zhang Hai <Dreaming.in.Code.ZH@Gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#

DIALOG=zenity

name=$(basename "$0")

account_type=
username=
password=

on_error() {
    echo "Error in $1:$2"
    exit "$?"
}
trap 'on_error "${BASH_SOURCE}" "${LINENO}"' ERR

usage() {
    # TODO
    cat <<EOF
Usage: ${name} [OPTIONS]

Options:

  -d, --disconnect          Disconnect from ZJU VPN
  -h, --help                Display this help and exit
  -l, --lac-conf=NAME       Use LAC configuration NAME; the default
                            configuration name is ${XL2TPD_LAC_CONF_DEFAULT}
  -t, --timeout=SECONDS     Time out after SECONDS; the default timeout is
                            ${TIMEOUT_DEFAULT}
EOF
}

error_exit() {
    echo "${@:1}" >&2
    exit 1
}

error_exit_if_empty() {
    if [[ -z "$1" ]]; then
        exit 1
    fi
}

dialog-login() {
    #"${DIALOG}" --title="$1" --text='请输入用户名和密码：' --forms --add-entry='用户名' --add-password='密码' --separator='|' 2>/dev/null
    # But --password does not support --separator
    "${DIALOG}" --title="$1" --text='请输入用户名和密码：' --username --password 2>/dev/null
}

dialog-list() {
    "${DIALOG}" --title="$1" --text="$2" --column='' --hide-header --list "${@:3}" 2>/dev/null
}

login() {
    while IFS='|' read file_username file_password file_account_type; do
        if [[ "${file_username}" = "${username}" ]] && [[ "${file_password}" = "${password}" ]] && [[ "${file_account_type}" = "${account_type}" ]]; then
            return 0
        fi
        echo "${file_username} ${file_password} ${file_account_type}"
    done <passwd
    error_exit "用户名、密码或账户类型错误"
}

main() {

    # Read account type.
    account_type=$(dialog-list '作业管理系统' '请选择账户类型：' '管理员' '教师' '学生')
    error_exit_if_empty "${account_type}"

    # Read username and password.
    local username_password
    username_password=$(dialog-login "${account_type}登录")
    error_exit_if_empty "${username_password}"
    username=$(echo "${username_password}" | cut -d'|' -f1)
    password=$(echo "${username_password}" | cut -d'|' -f2)

    # Login
    case "$account_type" in
        '管理员'|'教师'|'学生')
            login
            ;;
        --)
            error_exit '未预期的账户类型'
            ;;
    esac
}

main "$@"
