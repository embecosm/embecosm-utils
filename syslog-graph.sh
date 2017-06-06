#!/bin/sh

# Copyright (C) 2017 Embecosm Limited <www.embecosm.com>

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# Simple script to put syslog output from the router into a file.

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

#     syslog-graph.sh

# Prerequisites:

#     sudo dnf install fuse-sshfs


# Date as days suitable for gnuplot
datedays() {
    d1=$(date -d "$1" +%s)
    d2=$(date -d "1970-01-01" +%s)
    echo $(( (d1 - d2) / 86400 ))
}

# remdir=/tmp/syslog-graph-dir-$$
remdir=testing
remhost=192.168.44
tmpf1=/tmp/syslog-graph-tmp-1-$$
tmpf2=/tmp/syslog-graph-tmp-2-$$
tmpf3=/tmp/syslog-graph-tmp-3-$$
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
    grep '\(Shut Down from ADSL Phy\)\|SHOWTIME' $f | tac >> ${tmpf1}
done

for f in ${remdir}/syslog.*.gz
do
    gunzip -c $f | grep '\(WAN 1 is\)\|SHOWTIME' | tac >> ${tmpf1}
done

# Find the fields of interest, grepping out any data on Jan 1, which is change
# over of new router.
sed -n -e 's/\([[:alpha:]]\{3\}\) \([ [:digit:]]\{2\}\) \([[:digit:]]\{2\}\):\([[:digit:]]\{2\}\):\([[:digit:]]\{2\}\) .*WAN 1 is.*$/2017,\1,\2,\3,\4,\5,0,0,0,0/p' -e 's/\([[:alpha:]]\{3\}\) \([ [:digit:]]\{2\}\) \([[:digit:]]\{2\}\):\([[:digit:]]\{2\}\):\([[:digit:]]\{2\}\) .*SHOWTIME UpSpeed=\([[:digit:]]\+\) DownSpeed=\([[:digit:]]\+\) SNR=\([-[:digit:]]\+\) Atten=\([-[:digit:]]\+\).*/2017,\1,\2,\3,\4,\5,\6,\7,\8,\9/p' ${tmpf1} | tac > ${tmpf2}

# Break out the fields
rm ${tmpf1}
while IFS='' read -r line || [[ -n "${line}" ]]
do
    year=$(echo ${line} | cut -d ',' -f 1)
    mon=$(echo ${line} | cut -d ',' -f 2)
    day=$(echo ${line} | cut -d ',' -f 3 | sed -e 's/^0//')
    hour=$(echo ${line} | cut -d ',' -f 4 | sed -e 's/^0//')
    min=$(echo ${line} | cut -d ',' -f 5 | sed -e 's/^0//')
    sec=$(echo ${line} | cut -d ',' -f 6 | sed -e 's/^0//')
    up=$(echo ${line} | cut -d ',' -f 7)
    down=$(echo ${line} | cut -d ',' -f 8)
    snr=$(echo ${line} | cut -d ',' -f 9)
    atten=$(echo ${line} | cut -d ',' -f 10)

    if [ \( ${mon} != "Jan" \) -o \( ${day} -ne 1 \) ]
    then
	printf "%04d-%3s-%02d/%02d:%02d:%02d\t%d\t%d\t%d\t%d\n" ${year} ${mon} \
	       ${day} ${hour} ${min} ${sec} ${down} ${up} ${snr} ${atten} \
	       >> ${tmpf1}
    fi
done < ${tmpf2}

cat > ${tmpf3} <<EOF
set xlabel "date"
set xdata time
set timefmt "%Y-%b-%d/%H:%M:%S"
set format x "%d-%b"
set xrange ["2017-May-30/00:00:00" : "2017-Jun-07/00:00:00"]
set xtics out
set ytics out
set style line 1 lc rgb '#0060ad' lt 1 lw .1 pt 7 ps 1.5   # --- blue
set style line 2 lc rgb '#ad0060' lt 1 lw .1 pt 7 ps 1.5   # --- red
set style line 3 lc rgb '#60ad00' lt 1 lw .1 pt 7 ps 1.5   # --- green
set style line 4 lc rgb '#adad60' lt 1 lw .1 pt 7 ps 1.5   # --- yellow

set ylabel "speed"
set yrange ["0" : "100000000"]
plot 'tmpf1' using 1:2 linestyle 1 with lines title "down", \
     'tmpf1' using 1:3 linestyle 2 with lines title "up"

set terminal x11 1
set ylabel "value"
set yrange ["-10" : "20"]
plot 'tmpf1' using 1:4 linestyle 3 with lines title "SNR", \
     'tmpf1' using 1:5 linestyle 4 with lines title "attenuation"

set terminal pdf
set output "speed.pdf"
set ylabel "speed"
set yrange ["0" : "100000000"]
plot 'tmpf1' using 1:2 linestyle 1 with lines title "down", \
     'tmpf1' using 1:3 linestyle 2 with lines title "up"

set output "noise.pdf"
set ylabel "value"
set yrange ["-10" : "20"]
plot 'tmpf1' using 1:4 linestyle 3 with lines title "SNR", \
     'tmpf1' using 1:5 linestyle 4 with lines title "attenuation"
EOF

sed -i ${tmpf3} -e "s|tmpf1|${tmpf1}|"
gnuplot -persist ${tmpf3}

# Unmount when we are done - lazy to allow previous commands to catch up
fusermount -z -u ${remdir}
rmdir ${remdir}
rm -f ${tmpf1}
rm -f ${tmpf2}
rm -f ${tmpf3}
