#!/bin/sh

# Copyright (C) 2017 Embecosm Limited <www.embecosm.com>

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# Simple script to put record when the router is up or down.

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

#     updown-graph.sh

# Prerequisites:

#     sudo dnf install fuse-sshfs


remdir=/tmp/updown-graph-dir-$$
#remdir=testing
remhost=192.168.44
tmpf1=/tmp/updown-graph-tmp-1-$$
tmpf2=/tmp/updown-graph-tmp-2-$$
tmpf3=/tmp/updown-graph-tmp-3-$$
#tmpf1=tmpf1
#tmpf2=tmpf2
#tmpf3=tmpf3

# Mount the remote directory, unmounting first if already mounted
fusermount -q -u ${remdir} || true
rm -rf ${remdir}
mkdir ${remdir}
rm -f ${tmpf1}
rm -f ${tmpf2}
rm -f ${tmpf3}

if ! sshfs embadmin@${remhost}:/var/log ${remdir}
then
    echo "ERROR: Could not mount remote file system"
    exit 1
fi

for f in ${remdir}/syslog ${remdir}/syslog.1
do
    grep 'WAN 1 is' ${f} | tac >> ${tmpf1}
done

for f in ${remdir}/syslog.*.gz
do
    zcat ${f} | grep 'WAN 1 is' | tac >> ${tmpf1}
done

tac < ${tmpf1} | sed -e 's/DrayTek2/DrayTek/' > ${tmpf2}

# Break out the fields
rm ${tmpf1}
touch ${tmpf1}

prev="0.8"

while IFS='' read -r line || [[ -n "${line}" ]]
do
    mon=$(echo "${line}" | cut -c 1-3)
    day=$(echo "${line}" | cut -c 5-6 | sed -e 's/^ //')
    hour=$(echo "${line}" | cut -c 8-9 | sed -e 's/^0//')
    min=$(echo "${line}" | cut -c 11-12 | sed -e 's/^0//')
    sec=$(echo "${line}" | cut -c 14-15 | sed -e 's/^0//')
    dir=$(echo "${line}" | cut -c 47-48)

    if [ \( ${mon} != "Jan" \) -o \( ${day} -ne 1 \) ]
    then
	if [ ${dir} = "up" ]
	then
	    printf "2017-%3s-%02d/%02d:%02d:%02d\t%s\n" ${year} ${mon} \
		   ${day} ${hour} ${min} ${sec} ${prev} >> ${tmpf1}
	    prev="0.8"
	    printf "2017-%3s-%02d/%02d:%02d:%02d\t%s\n" ${year} ${mon} \
		   ${day} ${hour} ${min} ${sec} ${prev} >> ${tmpf1}
	else
	    printf "2017-%3s-%02d/%02d:%02d:%02d\t%s\n" ${year} ${mon} \
		   ${day} ${hour} ${min} ${sec} ${prev} >> ${tmpf1}
	    prev="0.2"
	    printf "2017-%3s-%02d/%02d:%02d:%02d\t%s\n" ${year} ${mon} \
		   ${day} ${hour} ${min} ${sec} ${prev} >> ${tmpf1}
	fi
    fi
done < ${tmpf2}

firstday=$(head -n 1 ${tmpf1} | cut -f 1 -d /)
lastday=$(tail -n 1 ${tmpf1} | cut -f 1 -d /)
cat > ${tmpf3} <<EOF
set xlabel "date"
set xdata time
set timefmt "%Y-%b-%d/%H:%M:%S"
set format x "%d-%b"
set border 3
set xrange ["firstday/00:00:00" : "lastday/23:59:59"]
set xtics out nomirror
set ytics out nomirror ("down" 0.2, "up" 0.8)
set style line 1 lc rgb '#0060ad' lt 1 lw .2 pt 7 ps 1.5   # --- blue

set ylabel "status"
set yrange ["0" : "1"]
plot 'tmpf1' using 1:2 linestyle 1 with lines title "status"

set terminal pdf
set output "status.pdf"
plot 'tmpf1' using 1:2 linestyle 1 with lines title "status"
EOF

sed -i ${tmpf3} -e "s|firstday|${firstday}|" -e "s|lastday|${lastday}|" \
    -e "s|tmpf1|${tmpf1}|"
gnuplot -persist ${tmpf3}

# Unmount when we are done - lazy to allow previous commands to catch up
fusermount -z -u ${remdir}
rmdir ${remdir}
rm -f ${tmpf1}
rm -f ${tmpf2}
rm -f ${tmpf3}
