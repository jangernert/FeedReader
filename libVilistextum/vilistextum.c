/*
 * Copyright (c) 1998-2006 Patric Müller
 * bhaak@gmx.net
 * http://bhaak.dyndns.org/vilistextum/
 *
 * Released under the GNU GPL Version 2 - http://www.gnu.org/copyleft/gpl.html
 */

#include <unistd.h>
#include <string.h>
#include <getopt.h>

#include <stdio.h>
#include <stdlib.h>

#include "vilistextum.h"
#include "html.h"
#include "fileio.h"
#include "charset.h"

/* ------------------------------------------------ */

char* vilistextum(char* text, int extractText)
{
	int nooutput = 0;
	int spaces = 0;
	int paragraph = 0;
	int breite = 76;
	int zeilen_len = 0;
	int zeilen_len_old = 0;
	
	if(text == NULL)
		return NULL;

	int error = 0;
	set_iconv_charset("utf-8");

	if(init_multibyte(error))
	{
		init_buffer(text, error);
		html(extractText, nooutput, spaces, paragraph, breite, error, zeilen_len, zeilen_len_old);
		finalize(nooutput, spaces, breite, error, zeilen_len, zeilen_len_old);
		
		char* output = getOutput(strlen(text));
		return output;
	}

	return NULL;
}
