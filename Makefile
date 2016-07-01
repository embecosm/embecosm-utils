# Basic Makefile for Embecosm utilities.

# Copyright (C) 2016 Embecosm Limited.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.  */

INSTALLDIR = $(HOME)/bin

CFLAGS = -g3 -O2

C_PROGS = rcmd-dump
SHELL_SCRIPTS = compress-pdf.sh

# Build everything

.PHONY: all
all: $(C_PROGS) $(SHELL_SCRIPTS)


# Install everything

.PHONY: install
install: all
	cp $(C_PROGS) $(INSTALLDIR)
	cp $(SHELL_SCRIPTS) $(INSTALLDIR)

# Clean up

.PHONY: clean
	$(RM) -f $(C_PROGS)

rcmd-dump: rcmd-dump.c
	$(CC) $(CFLAGS) -o $@ $<
