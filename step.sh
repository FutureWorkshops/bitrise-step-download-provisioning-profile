#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

#=======================================
# Functions
#=======================================

RESTORE='\033[0m'
RED='\033[00;31m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'

function color_echo {
	color=$1
	msg=$2
	echo -e "${color}${msg}${RESTORE}"
}

function echo_fail {
	msg=$1
	echo
	color_echo "${RED}" "${msg}"
	exit 1
}

function echo_warn {
	msg=$1
	color_echo "${YELLOW}" "${msg}"
}

function echo_info {
	msg=$1
	echo
	color_echo "${BLUE}" "${msg}"
}

function echo_details {
	msg=$1
	echo "  ${msg}"
}

function echo_done {
	msg=$1
	color_echo "${GREEN}" "  ${msg}"
}

function validate_required_input {
	key=$1
	value=$2
	if [ -z "${value}" ] ; then
		echo_fail "[!] Missing required input: ${key}"
	fi
}

function validate_required_input_with_options {
	key=$1
	value=$2
	options=$3

	validate_required_input "${key}" "${value}"

	found="0"
	for option in "${options[@]}" ; do
		if [ "${option}" == "${value}" ] ; then
			found="1"
		fi
	done

	if [ "${found}" == "0" ] ; then
		echo_fail "Invalid input: (${key}) value: (${value}), valid options: ($( IFS=$", "; echo "${options[*]}" ))"
	fi
}

#=======================================
# Main
#=======================================

#
# Validate parameters
echo_info "Configs:"
echo_details "* profile_name: ${profile_name}"
echo_details "* bundle_id: ${bundle_id}"
echo_details "* team_id: ${team_id}"
echo_details "* portal_username: ${portal_username}"
echo_details "* portal_password: ***"
echo_details "* deployment_type: ${deployment_type}"
echo_details "* target_variable: ${target_variable}"
echo_details "* target_filename: ${target_filename}"
echo_details "* fastlane_version: ${fastlane_version}"
echo

validate_required_input "profile_name" $profile_name
validate_required_input "bundle_id" $bundle_id
validate_required_input "team_id" $team_id
validate_required_input "portal_username" $portal_username
validate_required_input "portal_password" $portal_password
validate_required_input "deployment_type" $deployment_type
validate_required_input "target_variable" $target_variable
validate_required_input "target_filename" $target_filename
validate_required_input "fastlane_version" $fastlane_version

echo_info "Installing required gem: fastlane"
if [ "${fastlane_version}" == "latest" ] ; then
	if [ "$(fastlane -v | grep "^fastlane" | tail -1 )" != "" ] ; then
		gem install fastlane
	fi
else
	if [ "$(fastlane "_"$fastlane_version"_" -v | grep "^fastlane" | tail -1 )" != "fastlane ${fastlane_version}" ] ; then
		gem install fastlane -v $fastlane_version
	fi
fi

echo_info "Downloading provisioning profile"
export FASTLANE_PASSWORD="$portal_password"
ADHOC_FLAG=""
[ "${deployment_type}" == "ad-hoc" ] && ADHOC_FLAG="--adhoc"

COMMAND="sigh -u ${portal_username} 
-b ${team_id} 
-a ${bundle_id} 
${ADHOC_FLAG} 
-n \"${profile_name}\" 
-q \"${target_filename}\" 
--ignore_profiles_with_different_name --skip_certificate_verification"

if [ "${fastlane_version}" == "latest" ] ; then
	fastlane ${COMMAND}
else
	fastlane "_"$fastlane_version"_" ${COMMAND}
fi

echo_info "Setting environment variable"
envman add --key "${target_variable}" --value "file://./$target_filename"

