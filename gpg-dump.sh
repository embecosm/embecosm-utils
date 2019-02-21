#!/bin/sh
# Script to dump public GPG keys

# Copyright (C) 2019 Embecosm Limited

# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.

# SPDX-License-Identifier: GPL-3.0-or-later

# Get arg(s)

if [ $# -lt 2 ]
then
    echo "Usage: $0 <dump-file> <key> ..."
    exit 1
fi

file=$1
shift
emails="$*"

gpg --armor --output ${file} --export ${emails}

for e in ${emails}
do
    k=$(gpg --keyid-format long -k ${e} | \
	sed -n -e 's/^pub   //p' | \
	sed -e 's/ \[[[:alpha:]]\+\].#$//'   \
	    -e 's/rsa\([[:digit:]]\+\)/\1R/' \
	    -e 's/dsa\([[:digit:]]\+\)/\1D/')

    printf "  %s %s\n" "${k}" "${e}"
done
