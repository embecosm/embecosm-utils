#!/bin/sh

# Tool to search for content in a libre office calc file

# SPDX-License-Identifier: GPL-3.0-or-later

# Two arguments, search pattern, ODS filename. On success prints the file name
# and returns 0.  Returns 1 on failure, 2 on bad args.

if [ $# != 2 ]
then
    echo "Usage: $0 <pattern> <filename>"
    exit 2
fi

if unzip -p "$2" content.xml | grep -qi "$1"
then
    echo "$2"
    return 0
else
    return 1
fi
