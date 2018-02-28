/*
 * Copyright (c) 1998-2006 Patric Müller
 * bhaak@gmx.net
 * http://bhaak.dyndns.org/vilistextum/
 *
 * Released under the GNU GPL Version 2 - http://www.gnu.org/copyleft/gpl.html
 *
 */

#include <string.h>
#include <stdio.h>

#include "vilistextum.h"
#include "util.h"
#include "multibyte.h"

/* ------------------------------------------------ */

int unicode_entity(CHAR *s)
{
	int number;
  if (!convert_characters) { return(0); }

	number = extract_entity_number(s);

	switch (number) {
	case 8208: /* 0x2010 HYPHEN */
	case 8209: /* 0x2011 NON-BREAKING HYPHEN */
	 set_char(s, '-'); break;
  default:
		return(0);
	}

  return(1); /* found a transcription for entity */
} /* end unicode_entity */

/* ------------------------------------------------ */

int ligature_entity(CHAR *s)
{
	int number;
  if (!convert_characters) { return(0); }

	number = extract_entity_number(s);

	switch (number) {
	case 64256: /* FB00 LATIN SMALL LIGATURE FF */
		CPYSL(s, "ff"); break;
	case 64257: /* FB01 LATIN SMALL LIGATURE FI */
		CPYSL(s, "fi"); break;
	case 64258:	/* FB02 LATIN SMALL LIGATURE FL */
		CPYSL(s, "fl"); break;
	case 64259: /* FB03 LATIN SMALL LIGATURE FFI */
		CPYSL(s, "ffi"); break;
	case 64260: /* FB04 LATIN SMALL LIGATURE FFL */
		CPYSL(s, "ffl"); break;
	case 64261: /* FB05 LATIN SMALL LIGATURE LONG S T */
		CPYSL(s, "ft"); break;
	case 64262: /* FB06 LATIN SMALL LIGATURE ST */
		CPYSL(s, "st"); break;
  case 306: /* 0132 LATIN CAPITAL LIGATURE IJ */
		CPYSL(s, "IJ"); break;
	case 307: /* 0133 LATIN SMALL LIGATURE IJ */
		CPYSL(s, "ij"); break;
	case 338: /* 0152 LATIN CAPITAL LIGATURE OE */
		CPYSL(s, "OE"); break;
	case 339: /* 0153 LATIN SMALL LIGATURE OE */
		CPYSL(s, "oe"); break;
  default:
		return(0);
	}

  return(1); /* found a transcription for entity */
} /* end ligature_entity */

/* ------------------------------------------------ */
