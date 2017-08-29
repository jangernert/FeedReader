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

void set_options()
{
	convert_characters = 1;
	shrink_lines = 1;
	remove_empty_alt = 1;
	option_no_image = 1;
	option_no_alt = 1;
	convert_tags = 0;
	option_links = 0;
	option_links_inline = 0;
	option_title = 0;
	set_iconv_charset("utf-8");
	errorlevel = 0;
}

char* vilistextum(char* text, int extractText)
{
	int nooutput = 0;
	int spaces = 0;
	int paragraph = 0;
	int breite=76;
	
	if(text == NULL)
		return NULL;

	error = 0;
	set_options();

	if(init_multibyte())
	{
		init_buffer(text);
		html(extractText, nooutput, spaces, paragraph, breite);
		finalize(nooutput, spaces, breite);
		
		char* output = getOutput(strlen(text));
		return output;
	}

	return NULL;
}
