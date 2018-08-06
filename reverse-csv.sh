#!/bin/sh

# Copyright (C) 2018 Embecosm Limited <www.embecosm.com>

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# Simple script to reverse the lines in a CSV with title line.

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

# This script was prompted by my credit card, which allows me to download my
# statements as Comma Separated Values (CSV), but puts all the data in reverse
# order to the printed statement.

# tac will reverse the entire file. But I want to reverse all but the first
# line, which names the column headers.

# Reads from standard input and writes to standard output

head -1
sed -n -e '1,$p' | tac
