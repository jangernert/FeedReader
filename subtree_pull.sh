#!/bin/bash
if [[ "$1" == "grabberconfig" ]]; then
	prefix=data/GrabberConfig
	upstream=https://github.com/fivefilters/ftr-site-config.git
elif [[ "$1" == "libdecsync" ]]; then
	prefix=plugins/backend/decsync/libdecsync
	upstream=https://github.com/39aldo39/libdecsync-vala.git
else
	echo "Usage: $0 [grabberconfig|libdecsync]"
	echo "Pulls the latest changes for the given subtree"
	exit 1
fi

# Pull if the subtree exists, create if it doesn't
if [[ -d "$prefix" ]]; then
	cmd=pull
else
	cmd=add
fi

git subtree "$cmd" --prefix "$prefix" "$upstream" master --squash
