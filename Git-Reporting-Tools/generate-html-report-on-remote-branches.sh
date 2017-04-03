#!/bin/bash

BRANCH_AGE_THRESHOLD_DAYS=14

BASEPATH="$(dirname $0)"
BASENAME="$(basename $0)"
TEMPLATES_PATH="${BASEPATH}/html"

REPORT_HEADER_TEMPLATE="${TEMPLATES_PATH}/report-header.template"
REPORT_FOOTER_TEMPLATE="${TEMPLATES_PATH}/report-footer.template"
REPORT_ROW_TEMPLATE="${TEMPLATES_PATH}/report-row.template"

REPORT_FILE="${BASEPATH}/report.html"
CULPRITS_FILE="${BASEPATH}/culprits.csv"

source ${BASEPATH}/utils/git-utils.sh

function generate_report_for() {
	local report_file="${1}"
	local branches="${2}"

    for branch in ${branches}; do
        load_BRANCH_METADATA_for "${branch}"
        
        local last_commit_timestamp="${BRANCH_METADATA[2]}"
        local branch_age_days=$((($(date +%s) - $last_commit_timestamp) / 60 / 60 / 24))
        
        if [ "${branch_age_days}" -gt "${BRANCH_AGE_THRESHOLD_DAYS}" ]; then
            append_report_row \
                "${report_file}" \
                "${branch}" \
                "${branch_age_days}" \
                "${BRANCH_METADATA[0]}" \
                "${BRANCH_METADATA[1]}" \
                "${BRANCH_METADATA[3]}" \
                "${BRANCH_METADATA[4]}"
        fi
    done
}

function truncate_file() {
	local file="${1}"
	cat /dev/null > ${file}
}

function append_report_header() {
	local report_file="${1}"
	cat ${REPORT_HEADER_TEMPLATE} >> ${report_file}
}

function append_report_footer() {
	local report_file="${1}"
	cat ${REPORT_FOOTER_TEMPLATE} >> ${report_file}
}

function branch_age_to_color_class() {
	local branch_age_in_days="${1}"
	case 1 in
		$((${branch_age_in_days} >= 181)) ) echo "black";;
        $((${branch_age_in_days} <=  14)) ) echo "";;
		$((${branch_age_in_days} <=  30)) ) echo "yellow";;
		$((${branch_age_in_days} <=  60)) ) echo "orange";;
		$((${branch_age_in_days} <= 180)) ) echo "red";;
										* ) echo "";;
	esac 
}

function append_report_row() {
	local report_file="${1}"
	local branch="${2}"
	local branch_age_days="${3}"
	local last_commit_date="${4}"
	local last_commit_age="${5}"
	local author_name="${6}"
	local author_email="${7}"

	local td_color_class=$(branch_age_to_color_class ${branch_age_days})
	local row_template=$(<${REPORT_ROW_TEMPLATE})

	printf "${row_template}" \
		"$branch" \
		"$last_commit_date" \
		"${td_color_class}" "$last_commit_age" \
		"$author_email" "$author_name" \
		>> ${report_file}
}

function generate_culprits_list_for() {
	local culprits_file="${1}"
	local branches="${2}"
    local separator=""

    for branch in ${branches}; do
        load_BRANCH_METADATA_for "${branch}"
        
        local last_commit_timestamp="${BRANCH_METADATA[2]}"
        local branch_age_days=$((($(date +%s) - $last_commit_timestamp) / 60 / 60 / 24))
        local author_name="${BRANCH_METADATA[3]}"
        local author_email="${BRANCH_METADATA[4]}"
        
        if [ "${branch_age_days}" -gt "${BRANCH_AGE_THRESHOLD_DAYS}" ]; then
            printf "%s%s <%s>" \
                "${separator}" \
                "${author_name}" \
                "${author_email}" \
                >> ${culprits_file}
            separator="; "
        fi
    done
}

function parse_input_arguments() {
    for i in "$@"; do
        case "$i" in
            --report-file=*)
            REPORT_FILE="${i#*=}"
            shift
            ;;
            --extract-culprits)
            EXTRACT_CULPRITS=1
            shift
            ;;
            --culprits-file=*)
            CULPRITS_FILE="${i#*=}"
            EXTRACT_CULPRITS=1
            shift
            ;;
            --help|*)
            echo "Usage: ${BASENAME} [--report-file=<path>] [--extract-culprits] [--culprits-file=<path>]"
            exit 0
            ;;
        esac
    done
}

#
# MAIN
#
exit_if_not_inside_valid_git_repository
parse_input_arguments "$@"

echo "Generating HTML report to ${REPORT_FILE}..."

truncate_file "${REPORT_FILE}"
append_report_header "${REPORT_FILE}"
load_UNMERGED_REMOTE_BRANCHES
generate_report_for "${REPORT_FILE}" "${UNMERGED_REMOTE_BRANCHES}"
append_report_footer "${REPORT_FILE}"

if [ "${EXTRACT_CULPRITS}" ]; then
    echo "Generating culprits list to ${CULPRITS_FILE}..."
    truncate_file "${CULPRITS_FILE}"
    generate_culprits_list_for "${CULPRITS_FILE}" "${UNMERGED_REMOTE_BRANCHES}"
fi

echo "...done!"
