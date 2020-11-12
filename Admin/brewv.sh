#!/bin/bash
#
# Install specific version of a Homebrew formula
#
# Usage: brewv.sh install|upgrade formula_name desired_version
#
# Notes:
# - this may unshallow your brew repo copy. It might take some time the first time 
#   you call this script.
# - my "git log" uses less by default and when that happens it breaks the script 
#   Therefore we have the "--max-count=20" parameter. This might fail to find proper 
#   version if the one you wish to install is outside of this count.
#
# Origin Author: Stanimir Karoserov ( demosten@gmail.com )
# Edited: Alan Voiski ( alan@voiski.com )
#

tap=homebrew/homebrew-core
max_count=20
while test $# -gt 0; do
	case "$1" in
		-u|--unshallow)
			git -C "$(brew --repo homebrew/core)" fetch --unshallow || echo "Homebrew repo already unshallowed"
			;;
		-m|--max-count)
			max_count=$2
			shift
			;;
		-t|--tap)
			tap=$2
			shift
			;;
		install|upgrade)
			action=$1
			;;
		*)
			[ -z "${formula}" ] \
				&& formula=$1 \
				|| version=$1
			;;
	esac
	shift
done

if [ -z ${action} ] || [ -z ${formula} ]; then
	echo 'brewv.sh - installs specific version of a brew formula
syntax: brewv.sh <command> <options> <formula_name> <desired_version>
Command
install   Does the same of brew install
upgrade   Does the same of brew upgrade
Options
-u|--unshallow           Fetch the tap repository with unshallow option. Time
                         consuming, use only if you dont find your version.
-m|--max-count <value>   How deep it will go to find your version, default: 20
-t|--tap <value>         Which tap to search, default: homebrew/homebrew-core
Example
brewv.sh swiftformat 0.39.1
brewv.sh -u -m 200 swiftformat 0.01.1'
	exit 1
fi

if [ -z ${version} ];then
	echo 'Versions:'
	brew log --max-count=${max_count} --oneline ${formula}|grep -v ":"
	exit 0
fi

commit=$(brew log --max-count=${max_count} --oneline ${formula}|grep -F " ${version} "| head -n1| cut -d ':' -f1)

if [ -z "${commit}" ]; then
	echo "No version matching '${formula}' for '${version}'"
	exit 1
else 
	sha1=$(echo ${commit}| cut -d ' ' -f1)
	formula=$(echo ${commit}| cut -d ' ' -f2)
	(
		cd $(brew --repository)/Library/Taps/${tap};
		git checkout ${sha1} -- Formula/${formula}.rb;
		HOMEBREW_NO_AUTO_UPDATE=1 brew ${action} ${formula}
	)
fi
