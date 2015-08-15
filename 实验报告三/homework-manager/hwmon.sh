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

dialog-info() {
    "${DIALOG}" --info --title="信息" --text="$1"
}

dialog-error() {
    "${DIALOG}" --error --title="错误" --text="$1"
}

dialog-confirm() {
    "${DIALOG}" --question --title="确认" --text="$1"
    return "$?"
}

dialog-select() {
    "${DIALOG}"  --list --title="$1" --text="$2" --column='' --hide-header "${@:3}"
}

dialog-login() {
    # Following is ugly.
    #"${DIALOG}" --title="$1" --text='请输入用户名和密码：' --forms --add-entry='用户名' --add-password='密码' --separator='|' 2>/dev/null
    # But --password does not support --separator.
    "${DIALOG}" --username --title="$1" --text='请输入用户名和密码：' --password
}

dialog-form() {
    "${DIALOG}" --forms --title="$1" --text="$2" --separator='	' "${@:3}"
}

dialog-list() {
    "${DIALOG}" --list --title="$1" --text="$2" "${@:3}"
}

dialog-entry() {
    "${DIALOG}" --entry --title="$1" --text="$2" "${@:3}"
}

error() {
    dialog-error "$1"
    echo "$1" >&2
    return 1
}

error-exit() {
    error "$1"
    exit 1
}

error-if-empty() {
    if [[ -z "$1" ]]; then
        error "$2"
        return 1
    fi
    return 0
}

error-exit-if-empty() {
    if [[ -z "$1" ]]; then
        error "$2"
        exit 1
    fi
    return 0
}

error-if-not-empty() {
    if [[ -n "$1" ]]; then
        error "$2"
        return 1
    fi
    return 0
}

error-exit-if-not-empty() {
    if [[ -n "$1" ]]; then
        error "$2"
        exit 1
    fi
    return 0
}

login() {

    # Read account type.
    local account_type
    account_type=$(dialog-select '登录作业管理系统' '请选择账户类型：' '管理员' '教师' '学生')
    local account_file
    case "${account_type}" in
        '管理员')
            account_file='admintab'
            ;;
        '教师')
            account_file='teachertab'
            ;;
        '学生')
            account_file='studenttab'
            ;;
        '')
            return 0
            ;;
        *)
            error-exit '未预期的账户类型'
            ;;
    esac

    # Read username and password.
    local username_password
    username_password=$(dialog-login "${account_type}登录")
    error-exit-if-empty "${username_password}" '用户名密码为空'
    local username
    username=$(echo "${username_password}" | cut -d'|' -f1)
    local password
    password=$(echo "${username_password}" | cut -d'|' -f2)

    # Authenticate.
    while IFS='	' read file_username file_realname file_password; do
        if [[ "${file_username}" = "${username}" ]] && [[ "${file_password}" = "${password}" ]]; then
            echo "${account_type}"
            return 0
        fi
    done <"${account_file}"
    error-exit '用户名、密码或账户类型错误'
}

admin-manage-teacher() {
    while true; do
        # Read action.
        local action
        action=$(dialog-select '管理教师账户' '请选择操作：' '新建教师账户' '查看教师账户' '编辑教师账户' '删除教师账户')
        # Perform action.
        case "${action}" in
            '新建教师账户')
                local teacher
                teacher=$(dialog-form '新建教师账户' '教师账户信息' --add-entry='工号' --add-entry='姓名' --add-password='密码')
                if [[ -z "${teacher}" ]]; then
                    continue
                fi
                id=$(echo ${teacher} | cut -d'	' -f1)
                if [[ -z "${id}" ]]; then
                    error '教师账户工号为空'
                    continue
                fi
                if grep "^${id}	" teachertab; then
                    error "工号为 ${id} 的教师账户已经存在"
                    continue
                fi
                echo "${teacher}" >>teachertab
                dialog-info '新建教师账户成功'
                ;;
            '查看教师账户')
                dialog-list '查看教师账户' '教师账户列表：' --column='工号' --column='姓名' --column='密码' $(cat teachertab)
                ;;
            '编辑教师账户')
                id=$(dialog-entry '编辑教师账户' '请输入教师工号：')
                if [[ -z "${id}" ]]; then
                    continue
                fi
                if ! grep "^${id}	" teachertab; then
                    error "未找到工号为 ${id} 的教师"
                    continue
                fi
                name_password=$(dialog-form '编辑教师账户' "工号 ${id}" --add-entry='姓名' --add-password='密码')
                if [[ -z "${name_password}" ]]; then
                    continue
                fi
                if sed -i "s/^${id}	.*$/${id}	${name_password}/" teachertab; then
                    dialog-info "编辑教师账户成功"
                else
                    error "编辑教师账户失败"
                fi
                ;;
            '删除教师账户')
                id=$(dialog-entry '删除教师账户' '请输入教师工号：')
                if [[ -z "${id}" ]]; then
                    continue
                fi
                if ! grep "^${id}	" teachertab; then
                    error "未找到工号为 ${id} 的教师"
                    continue
                fi
                if ! dialog-confirm "确定要删除工号为 ${id} 的教师账户么？"; then
                    continue
                fi
                if sed -i "/^${id}	.*$/d" teachertab; then
                    dialog-info "删除教师账户成功"
                else
                    error "删除教师账户失败"
                fi
                ;;
            '')
                break
                ;;
            *)
                error "未预期的操作：\"${action}\""
                continue
                ;;
        esac
    done
    return 0
}

admin-manage-course() {
    while true; do
        # Read action.
        local action
        action=$(dialog-select '管理课程' '请选择操作：' '新建课程' '查看课程' '编辑课程' '删除课程')
        # Perform action.
        case "${action}" in
            '新建课程')
                local course
                course=$(dialog-form '新建课程' '课程信息' --add-entry='课号' --add-entry='名称' --add-entry='教师工号')
                if [[ -z "${course}" ]]; then
                    continue
                fi
                id=$(echo ${course} | cut -d'	' -f1)
                if [[ -z "${id}" ]]; then
                    error '课程课号为空'
                    continue
                fi
                if grep "^${id}	" coursetab; then
                    error "课号为 ${id} 的课程已经存在"
                    continue
                fi
                echo "${course}" >>coursetab
                dialog-info '新建课程成功'
                ;;
            '查看课程')
                dialog-list '查看课程' '课程列表：' --column='课号' --column='名称' --column='教师工号' $(cat coursetab)
                ;;
            '编辑课程')
                id=$(dialog-entry '编辑课程' '请输入课程课号：')
                if [[ -z "${id}" ]]; then
                    continue
                fi
                if ! grep "^${id}	" coursetab; then
                    error "未找到课号为 ${id} 的课程"
                    continue
                fi
                name_teacher=$(dialog-form '编辑课程' "课号 ${id}" --add-entry='名称' --add-entry='教师工号')
                if [[ -z "${name_teacher}" ]]; then
                    continue
                fi
                if sed -i "s/^${id}	.*$/${id}	${name_teacher}/" coursetab; then
                    dialog-info "编辑课程成功"
                else
                    error "编辑课程失败"
                fi
                ;;
            '删除课程')
                id=$(dialog-entry '删除课程' '请输入课程课号：')
                if [[ -z "${id}" ]]; then
                    continue
                fi
                if ! grep "^${id}	" coursetab; then
                    error "未找到课号为 ${id} 的课程"
                    continue
                fi
                if ! dialog-confirm "确定要删除课号为 ${id} 的课程么？"; then
                    continue
                fi
                if sed -i "/^${id}	.*$/d" coursetab; then
                    dialog-info "删除课程成功"
                else
                    error "删除课程失败"
                fi
                ;;
            '')
                break
                ;;
            *)
                error "未预期的操作：\"${action}\""
                continue
                ;;
        esac
    done
    return 0
}

admin-main() {
    while true; do
        # Read action.
        local action
        action=$(dialog-select '管理员操作' '请选择操作：' '管理教师账户' '管理课程')
        # Perform action.
        case "${action}" in
            '管理教师账户')
                admin-manage-teacher
                ;;
            '管理课程')
                admin-manage-course
                ;;
            '')
                break
                ;;
            *)
                error "未预期的操作：\"${action}\""
                continue
                ;;
        esac
    done
    return 0
}

teacher-manage-student() {
    while true; do
        # Read action.
        local action
        action=$(dialog-select '管理学生账户' '请选择操作：' '新建学生账户' '查看学生账户' '编辑学生账户' '删除学生账户')
        # Perform action.
        case "${action}" in
            '新建学生账户')
                local teacher
                teacher=$(dialog-form '新建学生账户' '学生账户信息' --add-entry='学号' --add-entry='姓名' --add-password='密码')
                if [[ -z "${teacher}" ]]; then
                    continue
                fi
                id=$(echo ${teacher} | cut -d'  ' -f1)
                if [[ -z "${id}" ]]; then
                    error '学生账户学号为空'
                    continue
                fi
                if grep "^${id}     " teachertab; then
                    error "学号为 ${id} 的学生账户已经存在"
                    continue
                fi
                echo "${teacher}" >>teachertab
                dialog-info '新建学生账户成功'
                ;;
            '查看学生账户')
                dialog-list '查看学生账户' '学生账户列表：' --column='学号' --column='姓名' --column='密码' $(cat teachertab)
                ;;
            '编辑学生账户')
                id=$(dialog-entry '编辑学生账户' '请输入学生学号：')
                if [[ -z "${id}" ]]; then
                    continue
                fi
                if ! grep "^${id}   " teachertab; then
                    error "未找到学号为 ${id} 的学生"
                    continue
                fi
                name_password=$(dialog-form '编辑学生账户' "学号 ${id}" --add-entry='姓名' --add-password='密码')
                if [[ -z "${name_password}" ]]; then
                    continue
                fi
                if sed -i "s/^${id}     .*$/${id}   ${name_password}/" teachertab; then
                    dialog-info "编辑学生账户成功"
                else
                    error "编辑学生账户失败"
                fi
                ;;
            '删除学生账户')
                id=$(dialog-entry '删除学生账户' '请输入学生学号：')
                if [[ -z "${id}" ]]; then
                    continue
                fi
                if ! grep "^${id}   " teachertab; then
                    error "未找到学号为 ${id} 的学生"
                    continue
                fi
                if ! dialog-confirm "确定要删除学号为 ${id} 的学生账户么？"; then
                    continue
                fi
                if sed -i "/^${id}  .*$/d" teachertab; then
                    dialog-info "删除学生账户成功"
                else
                    error "删除学生账户失败"
                fi
                ;;
            '')
                break
                ;;
            *)
                error "未预期的操作：\"${action}\""
                continue
                ;;
        esac
    done
    return 0
}

teacher-main() {
    while true; do
        # Read action.
        local action
        action=$(dialog-select '教师操作' '请选择操作：' '管理学生' '管理课程')
        # Perform action.
        case "${action}" in
            '管理学生')
                teacher-manage-student
                ;;
            '管理课程')
                admin-manage-course
                ;;
            '')
                break
                ;;
            *)
                error "未预期的操作：\"${action}\""
                continue
                ;;
        esac
    done
    return 0
}

main() {

    # Login
    local account_type
    account_type=$(login)
    if [[ -z "${account_type}" ]]; then
        return 0
    fi

    # Dispatch
    case "${account_type}" in
        '管理员')
            admin-main
            ;;
        '教师')
            teacher-main
            ;;
        '学生')
            student-main
            ;;
        *)
            error-exit "未预期的账户类型：\"${account_type}\""
            ;;
    esac
}

main "$@"
