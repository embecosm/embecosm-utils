#!/bin/sh

# Copyright (C) 2016 Embecosm Limited <www.embecosm.com>

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# Simple script to update a set of git working directories

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.

if [ $# -lt 1 ]
then
    echo "Usage update-all.sh <dir> [<dir> ...]"
fi

topdir=`pwd`

for d in $*
do

    if [ -d ${d} -a -e ${d}/.git ]
    then
	cd ${d}
	echo "Updating ${d}"
	git pull
    fi

    cd ${topdir}
done
