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

char buffer[DEF_STR_LEN];

/* ------------------------------------------------ */

void set_options()
{
	convert_characters = 1;
	option_output_utf8 = 1;
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

CHAR* vilistextum(char* text, int extractText)
{
	error = 0;

	if(init_multibyte())
	{
		use_default_charset();
		set_options();
		open_files(text);
		html(extractText);
		quit();
	}

	if(!error)
	{
		CHAR* output = getOutput();
		int ret = wcstombs ( buffer, output, sizeof(buffer) );
		memset(output,0,sizeof(DEF_STR_LEN));
		if (ret==DEF_STR_LEN) buffer[DEF_STR_LEN-1]='\0';
		if (ret)
			return buffer;
		else
			return NULL;
	}
	else
		return NULL;
}
