#!/bin/sh

# Copyright (C) 2016 Embecosm Limited <www.embecosm.com>

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# Simple script to compress a file.

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

# Usage:

#     compress-pdf.sh [-0 | -1 | -2 | -3 | -4] <file>.pdf

# Takes the supplied file, and does no compression (-0) through to maximum
# compression (-4, the default). Silently overwrites any existing compressed
# output file!

compress_level="/screen"

if [ $# -eq 2 ]
then
    case $1
    in
	-0)
	    compress_level="/none"
	    shift
	    ;;

	-1)
	    compress_level="/prepress"
	    shift
	    ;;

	-2)
	    compress_level="/printer"
	    shift
	    ;;

	-3)
	    compress_level="/ebook"
	    shift
	    ;;

	-4) compress_level="/screen"
	    shift
	    ;;

	*)
	    echo "Usage: compress-pdf.sh [-0 | -1 | -2 | -3 | -4] <file>.pdf"
	    exit 255
	    ;;
    esac
fi

if [ $# -ne 1 ]
then
    echo "Usage: compress-pdf.sh [-0 | -1 | -2 | -3 | -4] <file>.pdf"
    exit 255
fi

inf=$1
indir=$(dirname "${inf}")
inbase=$(basename "${inf}")
inext="${inbase##*.}"
infile="${inbase%.*}"

if [ "x${inext}" != "xpdf" ]
then
    echo "ERROR: Input file must have \".pdf\" suffix"
    exit 255
fi

outf="${indir}/${infile}-compressed.pdf"

if [ "${compress_level}" = "/none" ]
then
    cp ${inf} ${outf}
else
    gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 \
       -dPDFSETTINGS=${compress_level} -sOutputFile="${outf}" "${inf}"
fi
