#!/bin/bash
#
# A script to format SPEC CPU 2006 spec.ratio files
#
# Copyright (C) 2022 Embecosm <www.embecosm.com>
#
# Contributor: Jeremy Bennett <jeremy.bennett@embecosm.com>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# I am forever being asked to present SPEC CPU results on Markdown. This
# script just provides convenient formatting
#
#   Usage: format-spec.sh <spec.ratio file>
#
# Output is on standard output

if [ $# != 1 ]
then
    echo "Usage: format-spec.sh <spec.ratio file>"
fi

spec_file=$1

printf "| %-15s | %6s |\n" "Benchmark" "Ratio"
printf "| %-15s | %6s |\n" ":--------------" "-----:"
while read -r line
do
    if [[ "${line}" =~ ^[0-9] ]]
    then
	bm=$(echo ${line} | sed -e '/^[0-9]/s/ .*//')
	sr=$(echo ${line} | cut -d ' ' -f 4)
	printf "| %-15s | %6.2f |\n" "${bm}" "${sr}"
    elif [[ "${line}" =~ ^Spec ]]
    then
	sr=$(echo ${line} | cut -d ' ' -f 3)
	printf "| %-15s | %6s |\n" " " " "
	printf "| %-15s | %6.2f |\n" "SPEC ratio" "${sr}"
    fi
done < ${spec_file}
