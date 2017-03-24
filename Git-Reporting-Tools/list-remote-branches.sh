#!/bin/bash

BASEPATH="$(dirname $0)"
source ${BASEPATH}/utils/term-colors.sh
source ${BASEPATH}/utils/git-utils.sh

function print_branches_with_metadata() {
    for branch in ${1}; do
        load_BRANCH_METADATA_for $branch
        printf "%-50s ${GREEN}%s ${RED}%s ${YELLOW}%-26s ${GREY}%-36s ${COLOR_RESET}\n" \
            "$branch" \
            "${BRANCH_METADATA[0]}" \
            "${BRANCH_METADATA[1]}" \
            "${BRANCH_METADATA[3]}" \
            "${BRANCH_METADATA[4]}"
    done
}

exit_if_not_inside_valid_git_repository

echo "A list of remote branches merged into master and ${GREEN}safe to be deleted${COLOR_RESET}:"
load_MERGED_REMOTE_BRANCHES
print_branches_with_metadata "${MERGED_REMOTE_BRANCHES}"

echo
echo "A list of remote branches ${RED}NOT merged into master${COLOR_RESET}:"
load_UNMERGED_REMOTE_BRANCHES
print_branches_with_metadata "${UNMERGED_REMOTE_BRANCHES}"

