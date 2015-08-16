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
    username=$(echo "${username_password}" | cut -d'|' -f1)
    local password
    password=$(echo "${username_password}" | cut -d'|' -f2)

    # Authenticate.
    touch "${account_file}"
    while IFS='	' read file_username file_realname file_password; do
        if [[ "${file_username}" = "${username}" ]] && [[ "${file_password}" = "${password}" ]]; then
            echo "${account_type}"
            return 0
        fi
    done <"${account_file}"
    error-exit '用户名、密码或账户类型错误'
}

admin-manage-teacher() {
    touch teachertab
    while true; do
        # Read action.
        local action
        action=$(dialog-select '管理教师账户' '请选择操作：' '新建教师账户' '查看教师账户列表' '编辑教师账户' '删除教师账户')
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
            '查看教师账户列表')
                dialog-list '查看教师账户列表' '教师账户列表：' --column='工号' --column='姓名' --column='密码' $(cat teachertab)
                ;;
            '编辑教师账户')
                id=$(dialog-list '编辑教师账户' '选择教师账户：' --column='工号' --column='姓名' --column='密码' $(cat teachertab))
                if [[ -z "${id}" ]]; then
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
                id=$(dialog-list '删除教师账户' '选择教师账户：' --column='工号' --column='姓名' --column='密码' $(cat teachertab))
                if [[ -z "${id}" ]]; then
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
    touch coursetab
    while true; do
        # Read action.
        local action
        action=$(dialog-select '管理课程' '请选择操作：' '新建课程' '查看课程列表' '编辑课程' '删除课程')
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
            '查看课程列表')
                dialog-list '查看课程列表' '课程列表：' --column='课号' --column='名称' --column='教师工号' $(cat coursetab)
                ;;
            '编辑课程')
                local id
                id=$(dialog-list '编辑课程' '请选择课程：' --column='课号' --column='名称' --column='教师工号' $(cat coursetab))
                if [[ -z "${id}" ]]; then
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
                local id
                id=$(dialog-list '删除课程' '请选择课程：' --column='课号' --column='名称' --column='教师工号' $(cat coursetab))
                if [[ -z "${id}" ]]; then
                    continue
                fi
                if ! dialog-confirm "确定要删除课号为 ${id} 的课程么？"; then
                    continue
                fi
                if sed -i "/^${id}	.*$/d" coursetab && rm -r "${id}"; then
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

teacher-manage-course() {
    touch coursetab
    while true; do
        # Read action.
        local action
        action=$(dialog-select '管理课程' '请选择操作：' '新建课程' '查看课程列表' '编辑课程' '删除课程')
        # Perform action.
        case "${action}" in
            '新建课程')
                local course
                course=$(dialog-form '新建课程' '课程信息' --add-entry='课号' --add-entry='名称')
                if [[ -z "${course}" ]]; then
                    continue
                fi
                local id
                id=$(echo ${course} | cut -d'	' -f1)
                if [[ -z "${id}" ]]; then
                    error '课程课号为空'
                    continue
                fi
                if grep "^${id}	" coursetab; then
                    error "课号为 ${id} 的课程已经存在"
                    continue
                fi
                echo "${course}	${username}" >>coursetab
                dialog-info '新建课程成功'
                ;;
            '查看课程列表')
                dialog-list '查看课程列表' '课程列表：' --column='课号' --column='名称' --column='教师工号' $(grep "	${username}$" coursetab)
                ;;
            '编辑课程')
                id=$(dialog-list '编辑课程' '请选择课程：' --column='课号' --column='名称' --column='教师工号' $(grep "	${username}$" coursetab))
                if [[ -z "${id}" ]]; then
                    continue
                fi
                name=$(dialog-form '编辑课程' "课号 ${id}" --add-entry='名称')
                if [[ -z "${name}" ]]; then
                    continue
                fi
                if sed -i "s/^${id}	[^	]*/${id}	${name}/" coursetab; then
                    dialog-info "编辑课程成功"
                else
                    error "编辑课程失败"
                fi
                ;;
            '删除课程')
                id=$(dialog-list '删除课程' '请选择课程：' --column='课号' --column='名称' --column='教师工号' $(grep "	${username}$" coursetab))
                if [[ -z "${id}" ]]; then
                    continue
                fi
                if ! dialog-confirm "确定要删除课号为 ${id} 的课程么？"; then
                    continue
                fi
                if sed -i "/^${id}	.*$/d" coursetab && rm -r "${id}"; then
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

teacher-manage-student() {
    local course_id
    course_id=$(dialog-list '选择课程' '请选择课程：' --column='课号' --column='名称' --column='教师工号' $(grep "	${username}$" coursetab))
    if [[ -z "${course_id}" ]]; then
        return 0
    fi
    mkdir -p "${course_id}"
    touch "${course_id}/studenttab"
    while true; do
        # Read action.
        local action
        action=$(dialog-select '管理学生账户' '请选择操作：' '新建学生账户' '查看学生账户列表' '编辑学生账户' '删除学生账户')
        # Perform action.
        case "${action}" in
            '新建学生账户')
                local student
                student=$(dialog-form '新建学生账户' '学生账户信息' --add-entry='学号' --add-entry='姓名' --add-password='密码')
                if [[ -z "${student}" ]]; then
                    continue
                fi
                id=$(echo ${student} | cut -d'	' -f1)
                if [[ -z "${id}" ]]; then
                    error '学生账户学号为空'
                    continue
                fi
                if grep "^${id}	" "${course_id}/studenttab"; then
                    error "学号为 ${id} 的学生账户已经存在"
                    continue
                fi
                echo "${student}" >>"${course_id}/studenttab"
                dialog-info '新建学生账户成功'
                ;;
            '查看学生账户列表')
                dialog-list '查看学生账户列表' '学生账户列表：' --column='学号' --column='姓名' --column='密码' $(cat "${course_id}/studenttab")
                ;;
            '编辑学生账户')
                id=$(dialog-list '编辑学生账户' '选择学生账户：' --column='学号' --column='姓名' --column='密码' $(cat "${course_id}/studenttab"))
                if [[ -z "${id}" ]]; then
                    continue
                fi
                name_password=$(dialog-form '编辑学生账户' "学号 ${id}" --add-entry='姓名' --add-password='密码')
                if [[ -z "${name_password}" ]]; then
                    continue
                fi
                if sed -i "s/^${id}	.*$/${id}	${name_password}/" "${course_id}/studenttab"; then
                    dialog-info "编辑学生账户成功"
                else
                    error "编辑学生账户失败"
                fi
                ;;
            '删除学生账户')
                id=$(dialog-list '删除学生账户' '选择学生账户：' --column='学号' --column='姓名' --column='密码' $(cat "${course_id}/studenttab"))
                if [[ -z "${id}" ]]; then
                    continue
                fi
                if ! dialog-confirm "确定要删除学号为 ${id} 的学生账户么？"; then
                    continue
                fi
                if sed -i "/^${id}	.*$/d" "${course_id}/studenttab"; then
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

teacher-manage-homework() {
    local course_id
    course_id=$(dialog-list '选择课程' '请选择课程：' --column='课号' --column='名称' --column='教师工号' $(grep "	${username}$" coursetab))
    if [[ -z "${course_id}" ]]; then
        return 0
    fi
    mkdir -p "${course_id}"
    touch "${course_id}/homeworktab"
    while true; do
        # Read action.
        local action
        action=$(dialog-select '管理作业' '请选择操作：' '新建作业' '查看作业列表' '查看作业完成情况' '编辑作业' '删除作业')
        # Perform action.
        case "${action}" in
            '新建作业')
                local homework
                homework=$(dialog-form '新建作业' '作业信息' --add-entry='作业号' --add-entry='名称')
                if [[ -z "${homework}" ]]; then
                    continue
                fi
                id=$(echo ${homework} | cut -d'	' -f1)
                if [[ -z "${id}" ]]; then
                    error '作业号为空'
                    continue
                fi
                if grep "^${id}	" "${course_id}/homeworktab"; then
                    error "作业号为 ${id} 的作业已经存在"
                    continue
                fi
                echo "${homework}" >>"${course_id}/homeworktab"
                dialog-info '新建作业成功'
                ;;
            '查看作业列表')
                dialog-list '查看作业' '作业列表：' --column='作业号' --column='名称' $(cat "${course_id}/homeworktab")
                ;;
            '查看作业完成情况')
                id=$(dialog-list '编辑作业' '选择作业：' --column='作业号' --column='名称' $(cat "${course_id}/homeworktab"))
                if [[ -z "${id}" ]]; then
                    continue
                fi
                touch "${course_id}/${id}"
                dialog-list '查看作业完成情况' '作业完成情况：' --column='学号' --column='作业内容' $(cat "${course_id}/${id}")
                ;;
            '编辑作业')
                id=$(dialog-list '编辑作业' '选择作业：' --column='作业号' --column='名称' $(cat "${course_id}/homeworktab"))
                if [[ -z "${id}" ]]; then
                    continue
                fi
                name=$(dialog-form '编辑作业' "作业号 ${id}" --add-entry='名称')
                if [[ -z "${name}" ]]; then
                    continue
                fi
                if sed -i "s/^${id}	.*$/${id}	${name}/" "${course_id}/homeworktab"; then
                    dialog-info "编辑作业成功"
                else
                    error "编辑作业失败"
                fi
                ;;
            '删除作业')
                id=$(dialog-list '删除作业' '选择作业：' --column='作业号' --column='名称' $(cat "${course_id}/homeworktab"))
                if [[ -z "${id}" ]]; then
                    continue
                fi
                if ! dialog-confirm "确定要删除作业号为 ${id} 的作业么？"; then
                    continue
                fi
                if sed -i "/^${id}	.*$/d" "${course_id}/homeworktab" && rm "${course_id}/${id}"; then
                    dialog-info "删除作业成功"
                else
                    error "删除作业失败"
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
        action=$(dialog-select '教师操作' '请选择操作：' '管理课程' '管理学生' '管理作业')
        # Perform action.
        case "${action}" in
            '管理课程')
                teacher-manage-course
                ;;
            '管理学生')
                teacher-manage-student
                ;;
            '管理作业')
                teacher-manage-homework
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
    login
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
