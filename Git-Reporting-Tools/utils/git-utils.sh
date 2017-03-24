#!/bin/bash

function exit_if_not_inside_valid_git_repository() {
    `git status &>/dev/null`
    if [ $? -ne 0 ]; then
        echo "No Git repositories found!"
        exit 1
    fi
}

function load_MERGED_REMOTE_BRANCHES() {
    MERGED_REMOTE_BRANCHES=`git branch -r --sort=-committerdate --merged |grep -v 'origin/master'`
}

function load_UNMERGED_REMOTE_BRANCHES() {
    UNMERGED_REMOTE_BRANCHES=`git branch -r --sort=-committerdate --no-merged |grep -v 'origin/master'`
}

#
# Loads branch metadata array into BRANCH_METADATA global variable.
#
# Array contains:
# 0: last commit date (ISO)
# 1: last commit age
# 2: last commit date (Unix timestamp)
# 3: last commit author name
# 4: last commit author e-mail
#
function load_BRANCH_METADATA_for() {
    local branch_name="${1}"
    local metadata_string=`git show --format="%ci|%cr|%ct|%an|%ae" ${branch_name} | head -1`
    IFS='|' read -r -a BRANCH_METADATA <<< "$metadata_string"
}
