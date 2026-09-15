#!/usr/bin/env bash

# shellcheck disable=SC2317
function debug {
	export PS4='+ [${BASH_SOURCE[0]}:${LINENO}]: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
	set -x
	exec > >(tee debug) 2>&1
}

#debug

# Same as set -euE -o pipefail
#set -o errexit
#set -o nounset
#set -o errtrace
#set -o pipefail
#IFS=$'\n\t'

shopt -s globstar
shopt -s dotglob
shopt -s extglob

_script_name=$(basename -s .sh "$0")

#-----------------------------------
# Usage Section

function __show_help__ {
	cat << EOF
Usage: ${_script_name} [OPTIONS]

Description: Adds an icon [updates:n] to the command prompt if updates are
available. When called with no arguments, the script checks for a cache file
and updates it if necessary.

Options:
  -h, --help		Display this help message
  -u, --update-cache	Update the cache file now

Examples:
  ${_script_name}
  ${_script_name} -u
  ${_script_name} --update-cache
EOF

exit 2
}

# Install this script to $HOME/bin
# Copy this function to $HOME/.bashrc and add $(__updates_icon__) to PS1
function __updates_icon__ {
	if [[ -x $HOME/bin/update-notifier ]]; then
		$HOME/bin/update-notifier
	fi
}

#-----------------------------------
# Created: 2026-09-10T13:55:27-04:00
# Tristan M. Chase <tristan.m.chase@gmail.com>

#-----------------------------------
# Depends on:
#  list
#  of
#  dependencies

#-----------------------------------
# TODO Section (see ~/devel/conventional-commits/TODO for details)
# - [ ] Insert script
# - [ ] Clean up stray ;'s
# - [ ] Modify command substitution to "$(this_style)"
# - [ ] Rename function_name() to function __function_name__ /\w+\(\)
# - [ ] Rename $variables to "${_variables}" /\$\w+/s+1 @v vEl,{n
# - [ ] Check that _variable="variable definition" (make sure it's in quotes)
# - [ ] Update usage, description, and options section
# - [ ] Update dependencies section

#-----------------------------------
# License Section

# Put license here

#-----------------------------------

_cache_path="${HOME}/.cache" && mkdir -p "${_cache_path}"
_cache_file="${_cache_path}/updates-available"
_cache_icon="${_cache_path}/updates-available.icon"

# Test stuff
#echo 1 > "${_cache_file}"
#rm "${_cache_file}"

function __updates_available__ {
	[[ -r "${_cache_file}" ]] && __create_icon__
	__check_cache__
}

function __create_icon__ {
	local _updates_num=
	read _updates_num < "${_cache_file}"

	if [[ -n "$_updates_num" ]]; then
		if [[ "$_updates_num" -gt 0 ]]; then
			printf "[updates:"$_updates_num"]" > "${_cache_icon}"
		elif [[ "$_updates_num" = "0" ]] && [[ -e "${_cache_icon}" ]]; then
			rm -f "${_cache_icon}"
		fi
	fi
}

function __check_cache__ {
	# Checks if the cache file needs an update
	# If the cache file doesn't exist, create it
	if [[ ! -e "${_cache_file}" ]]; then
		__update_cache__
		# else check the mtime of these files
	else
		d0=$(($(stat -c %Y "${_cache_file}" 2>/dev/null)-5))
		d1=$(stat -c %Y /var/lib/apt)
		d2=$(stat -c %Y /var/lib/apt/lists)
		d3=$(stat -c %Y /var/log/dpkg.log)
		now=$(date +%s)
		delta=$(($now-$d0))
		# Run the update if any of these conditions is true
		if [[ $d0 -lt 0 ]] || [[ $d0 -lt $d1 ]] || [[ $d0 -lt $d2 ]] || [[ $d0 -lt $d3 ]] || [[ 3605 -lt $delta ]] ; then
			__update_cache__
		fi
	fi
}

function __update_cache__ {

	printf "[updates:...]" > "${_cache_icon}"
	local _file_lock="${_cache_file}.lock"
	renice 10 $$ >/dev/null 2>&1 || true
	ionice -c3 -p $$ >/dev/null 2>&1 || true
	flock -xn "${_file_lock}" apt-get -s -o Debug::NoLocking=true upgrade \
		| grep -c ^Inst > "${_cache_file}" 2>/dev/null &
	}

	function __updates_available_icon__ {
		if [[ -r "${_cache_icon}" ]]; then
			cat "${_cache_icon}"
		fi
	}

#-----------------------------------
# Get some basic options
# - [ ] refactor: rewrite options using getopt (refactor-options-getopt)
#shopt -s extglob
case "${1:-}" in
	(-h|--help) __show_help__ ; exit 2 ;;
	(-u|--update-cache) __update_cache__ ;;
	(-*|--*)  printf "%b\n" ""${_script_name}": Option \""${1:-}"\" not recognized."  1>&2 ; __show_help__ ; exit 2  1>&2 ;;
	#('') printf "%b\n" ""${_script_name}": Argument required." 1>&2 ; __show_help__ ; exit 2  1>&2 ;;
	#(*) _arg="${1:-}"
	(*) __updates_available__ && __updates_available_icon__
esac
