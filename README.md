# Embecosm Utilities

Various simple Linux utilities that have proved useful to Embecosm
staff. Often just one line scripts.

Freely available for reuse under the GNU General Public License version 3.
See the file `COPYING` for details.

## camera-off.sh/camera-on.sh

One line modprobe commands to turn a camera on and off.

## cfit.sh

Wrapper for clang-format for some common use cases.

## compress-pdf.sh

Takes a PDF file and compresses it by reducing the rendering quality with
GhostScript.

## gpg-dump.sh

Simple script to dump out public GPG keys into a file.

## ods-search.sh

Script to search through Open Document Format spreadsheet files. A brute force
way for looking at a lot of spreadsheets.

## rcmd-dump

Takes the hex encoded ASCII used by the GDB remote serial protocol qRcmd
packet and converts it to ASCII for ease of reading.

## reverse-csv.sh

Reverse the lines in a CSV with title line from standard input to standard
output.

## syslog-all.sh/syslog-graph.sh

Dumps out syslog info for diagnostics. Needs SNOBOL4 interpeter installed.

## thunder-prefs.sh

Dumps out thunderbird preferences cleanly.

## update-all.sh

Updates a set of git repositories

## updown-graph.sh

Produce graphs of router log info showing when comms went up and down. Useful
for finding evidence of a dodgy ASDL connection.
