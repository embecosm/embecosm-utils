/* Dump a qRcmd string

   Copyright (C) 2014 Embecosm Limited.

   Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3 of the License, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
   more details.

   You should have received a copy of the GNU General Public License along
   with this program.  If not, see <http://www.gnu.org/licenses/>.  */

#include <stdlib.h>
#include <stdio.h>

int
main (int   argc,
      char *argv[])

{
  char *str;
  int  i;

  if (2 != argc)
    {
      fprintf (stderr, "Usage: rcmd-dump <string>\n");
      exit (EXIT_FAILURE);
    }

  str = argv[1];

  /* Convert each pair of chars to ASCII */
  for (i = 0; (str[i] != '\0') && (str[i + 1] != '\0'); i += 2)
    {
      char ch[3];
      char val;

      ch[0] = str[i];
      ch[1] = str[i + 1];
      ch[2] = '\0';

      val = strtoul (ch, NULL, 16);
      printf ("%c", val);
    }

  printf ("\n");

}	/* main () */

