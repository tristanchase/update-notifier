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
Usage: ${_script_name} [OPTIONS] [<arguments>]

Description: 

Options:
  #-d, --debug	Enable debug mode (disabled for now)
  -h, --help	Display this help message

Examples:
  ${_script_name} foo
  ${_script_name} --debug bar
EOF

exit 2
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
	[[ -r "${_cache_file}" ]] && __print_updates__ "${_cache_file}"
	__update_needed__ "${_cache_file}"
}

function __print_updates__ {
	local u=
	read u < "$1"

	if [[ -n "$u" ]]; then
		if [[ "$u" -gt 0 ]]; then
			printf "[updates:"$u"]" > "${_cache_icon}"
		elif [[ "$u" = "0" ]] && [[ -e "${_cache_icon}" ]]; then
			rm -f "${_cache_icon}"
		fi
	fi
}

function __update_cache__ {
	local mycache=$1 flock="$1.lock"
	# Now we actually have to do hard computational work to calculate updates.
	# Let's try to be "nice" about it:
	renice 10 $$ >/dev/null 2>&1 || true
	ionice -c3 -p $$ >/dev/null 2>&1 || true
	# These are very computationally intensive processes.
	# Background this work, have it write to the cache files,
	# and let the next cache check pick up the results.
	# Ensure that no more than one of these run at a given time
	#flock -xn "$flock" apt-get -s -o Debug::NoLocking=true upgrade | grep -c ^Inst >$mycache 2>/dev/null
	#echo "Cache updated"
	flock -xn "$flock" apt-get -s -o Debug::NoLocking=true upgrade | grep -c ^Inst >$mycache 2>/dev/null &
}

function __update_needed__ {
	# Checks if we need to update the cache.
	local mycache=$1
	# The cache doesn't exist: create it
	[[ ! -e "$mycache" ]] && __update_cache__ "$mycache"

	d0=$(($(stat -c %Y $mycache 2>/dev/null)-5))
	d1=$(stat -c %Y /var/lib/apt)
	d2=$(stat -c %Y /var/lib/apt/lists)
	d3=$(stat -c %Y /var/log/dpkg.log)
	now=$(date +%s)
	delta=$(($now-$d0))

	if [[ $d0 -lt 0 ]] || [[ $d0 -lt $d1 ]] || [[ $d0 -lt $d2 ]] || [[ $d0 -lt $d3 ]] || [[ 3605 -lt $delta ]] ; then
		__update_cache__
	fi
}

__updates_available__

#-----------------------------------
# Get some basic options
# - [ ] refactor: rewrite options using getopt (refactor-options-getopt)
shopt -s extglob
case "${1:-}" in
#	(-d|--debug) __debugger__ ;;
	(-h|--help) __show_help__ ; exit 2 ;;
	(-p|--print-updates) __print_updates__ "${_cache_file}" ;;
	(-u|--update-cache) __update_cache__ "${_cache_file}";;
	(-*|--*)  printf "%b\n" ""${_script_name}": Option \""${1:-}"\" not recognized."  1>&2 ; __show_help__ ; exit 2  1>&2 ;;
	#('') printf "%b\n" ""${_script_name}": Argument required." 1>&2 ; __show_help__ ; exit 2  1>&2 ;;
	(*) _arg="${1:-}"
esac
