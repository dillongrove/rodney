#!/bin/bash

# http://stackoverflow.com/questions/3878624/how-do-i-programmatically-determine-if-there-are-uncommited-changes
require_clean_work_tree () {
    # Update the index
    git update-index -q --ignore-submodules --refresh
    err=0

    # Disallow unstaged changes in the working tree
    if ! git diff-files --quiet --ignore-submodules --
    then
        echo >&2 "cannot $1: you have unstaged changes."
        git diff-files --name-status -r --ignore-submodules -- >&2
        err=1
    fi

    # Disallow uncommitted changes in the index
    if ! git diff-index --cached --quiet HEAD --ignore-submodules --
    then
        echo >&2 "cannot $1: your index contains uncommitted changes."
        git diff-index --cached --name-status -r --ignore-submodules HEAD -- >&2
        err=1
    fi

    if [ $err = 1 ]
    then
        echo >&2 "Please commit or stash them."
        exit 1
    fi
}

orig_branch=`git symbolic-ref HEAD` || exit 1

require_clean_work_tree

release="$1"

if [[ -z "$release" || ! "$release" =~ ^2\.[0-9]+(\.[0-9]+|alpha[0-9]+|beta[0-9]+)$ ]] ; then
	echo "Usage:"
	echo "  $0  release-tag"
	echo
	echo "Release tag must match r'2\.\d+(\.\d+|alpha\d+|beta\d+)'"
	exit 1
fi

git checkout "$release" || exit 1

make clean
if sed -i -e's/^version.*/version = "'$release'"/' setup.py ; then
	rm -f pyxmpp2/version.py 2>/dev/null
	if python setup.py check && make dist && python setup.py bdist_egg && python3 setup.py build --build-base=py3-build bdist_egg ; then
		python setup.py --verbose register --strict
	fi
fi
git checkout setup.py

git checkout "${orig_branch#refs/heads/}"
