#!/bin/bash

# Simple script to run clang-format

# Copyright (C) 2021 Embecosm Limited <www.embecosm.com>
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# SPDX-License-Identifier: GPL-3.0-or-later

# Usage: cfit.sh MS|GNU|LLVM [file ...]

# If no files are specified, format all C and C++ source and headers in the
# directory.

if [ $# -lt 1 ]
then
    echo "Usage: cfit.sh MS|LLVM [file ...]"
    exit 1
fi

case $1
in
    MS|Microsoft) style=Microsoft
	;;

    GNU) style=GNU
	 ;;

    LLVM) style=LLVM
	  ;;

    *) echo "Unknown style \"$1\""
       exit 1
       ;;
esac

shift

if [ $# -lt 1 ]
then
    files=$(ls -1 | grep '\(\.cpp$\)\|\(\.c$\)\|\(\.h$\)')
else
    files=$*
fi

if [ "x${files}" != "x" ]
then
    for f in ${files}
    do
	if [ ! -w ${f} ]
	then
	    echo "${f} not writable: ignored"
	else
	    echo ${f}
	    clang-format -i --style=${style} ${f}
	fi
    done
fi
