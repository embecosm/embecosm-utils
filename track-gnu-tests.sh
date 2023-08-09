#!/bin/bash

# Copyright (C) 2022 Embecosm Limited.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# SPDX-License-Identifier: GPL-3.0-or-later

# A script to generate a current total for running GNU tests.

# Helper to dump out usage
usage () {
    echo "Usage: <args>"
    echo ""
    echo "   -h|--help:    print this message."
    echo "   --binutils=<testsuite>   Check on binutils tests."
    echo "   --gas=<testsuite>        Check on gas tests."
    echo "   --ld=<testsuite>         Check on ld tests."
    echo "   --gcc=<testsuite>        Check on gcc tests."
    echo "   --newlib=<testsuite>     Check on newlib tests."
    echo "   --glibc=<testsuite>      Check on glibc tests."
    echo "   --gdb=<testsuite>        Check on gdb tests."
    echo ""
    echo "<testsuite> is the root of the built tests to check."
}

# Helper to process the logs once we have them. First argument is the tool
# name, all other arguments are files to look in.
do_counts () {
    pref=$1
    shift 1

    # Build up the counts
    passno=$(grep "^PASS:" $* | wc -l)
    failno=$(grep "^FAIL:" $* | wc -l)
    xpassno=$(grep "^XPASS:" $* | wc -l)
    xfailno=$(grep "^XFAIL:" $* | wc -l)
    kfailno=$(grep "^KFAIL:" $* | wc -l)
    unresolvedno=$(grep "^UNRESOLVED:" $* | wc -l)
    untestedno=$(grep "^UNTESTED:" $* | wc -l)
    unsupportedno=$(grep "^UNSUPPORTED:" $* | wc -l)
    pathno=$(grep "^PATH:" $* | wc -l)
    duplicateno=$(grep "^DUPLICATE:" $* | wc -l)
    total=$(( passno + failno + xpassno + xfailno + kfailno + unresolvedno \
		     + unsupportedno + untestedno + pathno + duplicateno ))

    if [[ ${total} = 0 ]]
    then
	echo
	echo "No test results for ${pref}"
    else
	# Put out the results
	printf "\n"
	printf "               === ${pref} Summary === \n"
	printf "\n"
	if [[ ${passno} != 0 ]]
	then
	    printf "# of expected passes       %9d\n" ${passno}
	fi
	if [[ ${failno} != 0 ]]
	then
	    printf "# of unexpected failures   %9d\n" ${failno}
	fi
	if [[ ${xpassno} != 0 ]]
	then
	    printf "# of unexpected successes  %9d\n" ${xpassno}
	fi
	if [[ ${xfailno} != 0 ]]
	then
	    printf "# of expected failures     %9d\n" ${xfailno}
	fi
	if [[ ${kfailno} != 0 ]]
	then
	    printf "# of known failures        %9d\n" ${kfailno}
	fi
	if [[ ${unresolvedno} != 0 ]]
	then
	    printf "# of unresolved testcases  %9d\n" ${unresolvedno}
	fi
	if [[ ${untestedno} != 0 ]]
	then
	    printf "# of untested tests        %9d\n" ${untestedno}
	fi
	if [[ ${unsupportedno} != 0 ]]
	then
	    printf "# of unsupported tests     %9d\n" ${unsupportedno}
	fi
	if [[ ${pathno} != 0 ]]
	then
	    printf "# of paths in test names   %9d\n" ${pathno}
	fi
	if [[ ${duplicateno} != 0 ]]
	then
	    printf "# of duplicate test names  %9d\n" ${duplicateno}
	fi
    fi
}

CMDS=$(getopt -o h -l help,binutils:,gas:,ld:,gcc:,newlib:,glibc:,gdb: -- "$@")
eval set -- "${CMDS}"

testsuite_binutils=
testsuite_gas=
testsuite_ld=
testsuite_gcc=
testsuite_newlib=
testsuite_glibc=
testsuite_gdb=

while true
do
    case "$1"
    in
	-h|--help)
	    usage
	    exit 0
	    ;;
	--binutils)
	    testsuite_binutils=$(realpath $2)
	    shift 2
	    ;;
	--gas)
	    testsuite_gas=$(realpath $2)
	    shift 2
	    ;;
	--ld)
	    testsuite_ld=$(realpath $2)
	    shift 2
	    ;;
	--gcc)
	    testsuite_gcc=$(realpath $2)
	    shift 2
	    ;;
	--newlib)
	    testsuite_newlib=$(realpath $2)
	    shift 2
	    ;;
	--glibc)
	    testsuite_glibc=$(realpath $2)
	    shift 2
	    ;;
	--gdb)
	    testsuite_gdb=$(realpath $2)
	    shift 2
	    ;;
	--)
	    shift 1
	    break
	    ;;
	*)
	    usage
	    exit 1
	    ;;
    esac
done

if [[ -d ${testsuite_gcc} ]]
then
    (
	# Look at GCC, G++ and fortran tests
	cd ${testsuite_gcc}
	for pref in gcc g++ gfortran
	do
	    # If the base directory doesn't exist, there is nothing to see here!
	    if [[ -e ${pref}/${pref}.sum ]]
	    then
		do_counts ${pref} ${pref}*/*.sum
	    else
		printf "\nNo test directories for ${pref}\n"
		continue
	    fi
	done
    )
fi

if [[ -d ${testsuite_gdb} ]]
then
    (
	# Look at GDB tests. This is only ever in a single file.
	cd ${testsuite_gdb}

	if [[ -e gdb.sum ]]
	then
	    do_counts gdb gdb.sum
	else
	    echo "No test directories for gdb"
	fi
    )
fi
