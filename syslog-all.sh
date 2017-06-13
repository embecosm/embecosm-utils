#!/bin/sh

# Copyright (C) 2017 Embecosm Limited <www.embecosm.com>

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# General script to handle syslog data

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
#     SNOBOL4 installation (see http://www.snobol4.org/csnobol4/curr/)
#     SSH public key on loglady

###############################################################################
#
# Mount the remote directory
#
###############################################################################

remdir=/tmp/syslog-all-dir-$$
#remdir=testing
remhost=loglady

# Unmount first if already mounted

fusermount -q -u ${remdir} || true
rm -rf ${remdir}
mkdir ${remdir}

if ! sshfs embadmin@${remhost}:/var/log ${remdir}
then
    echo "ERROR: Could not mount remote file system"
    exit 1
fi


###############################################################################
#
# Strip out irrelevant content from all the syslogs and make one unified file.
#
###############################################################################

tmpf1=/tmp/syslog-all-tmp-1-$$
tmpf2=/tmp/syslog-all-tmp-2-$$
updowndat=/tmp/syslog-all-tmp-3-$$
speeddat=/tmp/syslog-all-tmp-4-$$
#tmpf1=tmpf1
#tmpf2=tmpf2
#updowndat=updown.dat
#speeddat=speed.dat
rm -f ${tmpf1}
rm -f ${tmpf2}

# We are not interested in messages at the TCP/UDP level

echo "Gathering data from current logs"

for f in ${remdir}/syslog ${remdir}/syslog.1
do
    grep -v 'TCP\|UDP\|ICMP\|DNS' ${f} | tac >> ${tmpf1}
done

echo "Gathering data from historic logs"

for f in ${remdir}/syslog.?.gz ${remdir}/syslog.??.gz
do
    zcat ${f} | grep -v 'TCP\|UDP\|ICMP\|DNS' | tac >> ${tmpf1}
done

tac < ${tmpf1} | sed -e 's/DrayTek2/DrayTek/' > ${tmpf2}

###############################################################################
#
# Now process the data
#
###############################################################################

# Use SNOBOL4 to do the processing.

# Processing the data

snobol4 syslog-all.sno ${tmpf2} ${updowndat} ${speeddat}

firstday=$(head -n 1 ${updowndat} | cut -f 1 -d /)
lastday=$(tail -n 1 ${updowndat} | cut -f 1 -d /)


###############################################################################
#
# Plot the results
#
###############################################################################

echo "Plotting a graph"

cat > ${tmpf2} <<EOF
set xlabel "date"
set xdata time
set timefmt "%Y-%b-%d/%H:%M:%S"
set format x "%d-%b"
set border 3
set xrange ["firstday/00:00:00" : "lastday/23:59:59"]
set xtics out nomirror
set style line 1 lc rgb '#0000ff' lt 1 lw .2 pt 7 ps 1.5   # --- blue
set style line 2 lc rgb '#00ff00' lt 1 lw .2 pt 7 ps 1.5   # --- green
set style line 3 lc rgb '#ff0000' lt 1 lw .2 pt 7 ps 1.5   # --- red
set style line 4 lc rgb '#ffff00' lt 1 lw .2 pt 7 ps 1.5   # --- yellow

set margins 12, 2, 4, 2

set ylabel "status"
set yrange ["0" : "12"]
set ytics out nomirror ("DSL down" 1, "DSL up" 4, "PPP down" 6, "PPP up" 9)
plot 'updowndat' using 1:2 linestyle 1 with lines title "DSL status", \
     'updowndat' using 1:3 linestyle 2 with lines title "PPP status"

set terminal x11 1
set ylabel "speed"
set yrange ["0" : "100000000"]
unset ytics
set ytics out nomirror
plot 'speeddat' using 1:2 linestyle 1 with lines title "Speed up", \
     'speeddat' using 1:3 linestyle 2 with lines title "Speed sown"

set terminal x11 2
set ylabel "noise"
set yrange ["-10" : "25"]
unset ytics
set ytics out nomirror
plot 'speeddat' using 1:4 linestyle 1 with lines title "SNR", \
     'speeddat' using 1:5 linestyle 2 with lines title "Attenuation"

set terminal pdf

set output "status.pdf"
set ylabel "status"
set yrange ["0" : "12"]
set ytics out nomirror ("DSL down" 1, "DSL up" 4, "PPP down" 6, "PPP up" 9)
plot 'updowndat' using 1:2 linestyle 1 with lines title "DSL status", \
     'updowndat' using 1:3 linestyle 2 with lines title "PPP status"

set output "speed.pdf"
set ylabel "speed"
set yrange ["0" : "100000000"]
unset ytics
set ytics out nomirror
plot 'speeddat' using 1:2 linestyle 1 with lines title "Speed up", \
     'speeddat' using 1:3 linestyle 2 with lines title "Speed sown"

set output "noise.pdf"
set ylabel "noise"
set yrange ["-10" : "25"]
unset ytics
set ytics out nomirror
plot 'speeddat' using 1:4 linestyle 1 with lines title "SNR", \
     'speeddat' using 1:5 linestyle 2 with lines title "Attenuation"
EOF

sed -i ${tmpf2} -e "s|firstday|${firstday}|" -e "s|lastday|${lastday}|" \
    -e "s|updowndat|${updowndat}|g" -e "s|speeddat|${speeddat}|g"
gnuplot -persist ${tmpf2}


###############################################################################
#
# Tidy up
#
###############################################################################

# Remove temporary files

rm -f ${tmpf1}
rm -f ${tmpf2}
rm -f ${updowndat}
rm -f ${speeddat}

# Lazy unmount to allow previous commands to catch up

fusermount -z -u ${remdir}
rmdir ${remdir}
