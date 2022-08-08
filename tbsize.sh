#!/bin/sh

# A script to set the general font for Thunderbird.

# Copyright (C) 2022 Embecosm Limited <www.embecosm.com>
# Contributor: Jeremy Bennett <jeremy.bennett@embecosm.com>

# SPDX-License-Identifier: GPL-3.0-or-later

# Optional argument is size to set as number of synonym

case $#
in
    0)
	sz=12
	;;
    1)
	case $1
	in
	    hd)
		sz=12
		;;

	    4k)
		sz=18
		;;

	    [0-9]*)
		sz=$(echo $1 | sed -e 's/[^0-9]*//g')
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

cd ${HOME}/.thunderbird

for f in */chrome/userChrome.css
do
    sed -i -e "s/font-size: .\+px !important/font-size: ${sz}px !important/" ${f}
done

echo "Base font size set to ${sz}px. Will apply when Thunderbird is restarted"
