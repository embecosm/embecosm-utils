#!/bin/sh

# A script to set the general font for Thunderbird.

# Copyright (C) 2022 Embecosm Limited <www.embecosm.com>
# Contributor: Jeremy Bennett <jeremy.bennett@embecosm.com>

# SPDX-License-Identifier: GPL-3.0-or-later

# Optional argument is size to set as number of synonym

case $#
in
    0)
	fsz=12
	;;
    1)
	case $1
	in
	    hd)
		fsz=12
		;;

	    4k)
		fsz=18
		;;

	    [0-9]*)
		fsz=$(echo $1 | sed -e 's/[^0-9]*//g')
		;;

	    *)
		echo "Usage: $0 [<size>]"
		exit 1
		;;
	esac
	;;

    *)
	echo "Usage: $0 [<size>]"
	exit 1
	;;
esac

lsz=$(( fsz * 4 / 3 ))

cd ${HOME}/.thunderbird

for f in */chrome/userChrome.css
do
    sed -i -e "s/font-size: .\+px !important/font-size: ${fsz}px !important/" ${f}
    sed -i -e "s/height: .\+px !important/height: ${lsz}px !important/" ${f}
done

echo "Base font size set to ${fsz}px, line spacing ${lsz}px."
echo "Will apply when Thunderbird is restarted"
