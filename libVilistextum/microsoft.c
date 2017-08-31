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

#include "text.h"
#include "vilistextum.h"
#include "util.h"
#include "multibyte.h"
#include "microsoft.h"

/* ------------------------------------------------ */

int microsoft_entities(CHAR *s)
{
	int number = extract_entity_number(s);

	/* Euro */
	if (number==128)       	    { CPYSL(s, "EUR"); }
	else if CMP("&euro;", s)    { CPYSL(s, "EUR"); }
	else if (number==8364)      { CPYSL(s, "EUR"); }

	/* Single Low-9 Quotation Mark */
	else if (number==130)       { set_char(s, ','); }
	else if CMP("&sbquo;", s)   { set_char(s, ','); }
	else if (number==8218)      { set_char(s, ','); }

	else if (number==131)       { set_char(s, 'f'); } /* Latin Small Letter F With Hook */
	else if CMP("&fnof;", s)    { set_char(s, 'f'); } /* Latin Small Letter F With Hook */
	else if (number==402)       { set_char(s, 'f'); } /* Latin Small Letter F With Hook */

	/* Double Low-9 Quotation Mark */
	else if (number==132)       { CPYSL(s, "\""); }
	else if CMP("&bdquo;", s)   { CPYSL(s, "\""); }
	else if (number==8222)      { CPYSL(s, "\""); }

	else if (number==133)       { CPYSL(s, "..."); } /* Horizontal Ellipsis */
	else if CMP("&hellip;", s)  { CPYSL(s, "..."); } /* Horizontal Ellipsis */
	else if (number==8230)      { CPYSL(s, "..."); } /* Horizontal Ellipsis */

	/* Dagger */
	else if (number==134)       { CPYSL(s, "/-"); }
	else if CMP("&dagger;", s)  { CPYSL(s, "/-"); }
	else if (number==8224)      { CPYSL(s, "/-"); }

	/* Double Dagger */
	else if (number==135)       { CPYSL(s, "/="); }
	else if CMP("&Dagger;", s)  { CPYSL(s, "/="); }
	else if (number==8225)      { CPYSL(s, "/="); }

	/* Modifier Letter Circumflex Accent */
	else if (number==136)       { set_char(s, '^'); }
	else if CMP("&circ;", s)    { set_char(s, '^'); }
	else if (number==710)       { set_char(s, '^'); }

	/* Per Mille Sign */
	else if (number==137)       { CPYSL(s, "0/00"); }
	else if CMP("&permil;", s)  { CPYSL(s, "0/00"); }
	else if (number==8240)      { CPYSL(s, "0/00"); }

	/* Latin Capital Letter S With Caron */
	else if (number==138)       { set_char(s, 'S'); }
	else if CMP("&Scaron;", s)  { set_char(s, 'S'); }
	else if (number==352)       { set_char(s, 'S'); }

	/* Single Left-Pointing Angle Quotation Mark */
	else if (number==139)       { set_char(s, '<'); }
	else if CMP("&lsaquo;", s)  { set_char(s, '<'); }
	else if (number==8249)      { set_char(s, '<'); }

	/* Latin Capital Ligature OE */
	else if (number==140)       { CPYSL(s, "OE"); }
	else if CMP("&OElig;", s)   { CPYSL(s, "OE"); }
	else if (number==338)       { CPYSL(s, "OE"); }

	/* Z\/ */
	else if (number==142)       { set_char(s, 'Z'); }
	else if (number==381)       { set_char(s, 'Z'); }

	/* Left Single Quotation Mark */
	else if (number==145)       { set_char(s, '`'); }
	else if CMP("&lsquo;", s)   { set_char(s, '`'); }
	else if (number==8216)      { set_char(s, '`'); }

	/* Right Single Quotation Mark */
	else if (number==146)       { set_char(s, '\''); }
	else if CMP("&rsquo;", s)   { set_char(s, '\''); }
	else if (number==8217)      { set_char(s, '\''); }

	/* Left Double Quotation Mark */
	else if (number==147)       { set_char(s, '"'); }
	else if CMP("&ldquo;", s)   { set_char(s, '"'); }
	else if (number==8220)      { set_char(s, '"'); }

	/* Right Double Quotation Mark */
	else if (number==148)       { set_char(s, '"'); }
	else if CMP("&rdquo;", s)   { set_char(s, '"'); }
	else if (number==8221)      { set_char(s, '"'); }

	/* Bullet */
	else if (number==149)       { set_char(s, '*'); }
	else if CMP("&bull;", s)    { set_char(s, '*'); }
	else if (number==8226)      { set_char(s, '*'); }

	/* En Dash */
	else if (number==150)       { set_char(s, '-'); }
	else if CMP("&ndash;", s)   { set_char(s, '-'); }
	else if (number==8211)      { set_char(s, '-'); }

	/* Em Dash */
	else if (number==151)       { CPYSL(s, "--"); }
	else if CMP("&mdash;", s)   { CPYSL(s, "--"); }
	else if (number==8212)      { CPYSL(s, "--"); }

	/* Small Tilde */
	else if (number==152)       { set_char(s, '~'); }
	else if CMP("&tilde;", s)   { set_char(s, '~'); }
	else if (number==732)       { set_char(s, '~'); }

	/* Trade Mark Sign */
	else if (number==153)       { CPYSL(s, "[tm]"); }
	else if CMP("&trade;", s)   { CPYSL(s, "[tm]"); }
	else if (number==8482)      { CPYSL(s, "[tm]"); }

	/* Latin Small Letter S With Caron */
	else if (number==154)       { set_char(s, 's'); }
	else if CMP("&scaron;", s)  { set_char(s, 's'); }
	else if (number==353)       { set_char(s, 's'); }

	/* Single Right-Pointing Angle Quotation Mark */
	else if (number==155)       { set_char(s, '>'); }
	else if CMP("&rsaquo;", s)  { set_char(s, '>'); }
	else if (number==8250)      { set_char(s, '>'); }

	/* Latin Small Ligature OE */
	else if (number==156)       { CPYSL(s, "oe"); }
	else if CMP("&oelig;", s)   { CPYSL(s, "oe"); }
	else if (number==339)       { CPYSL(s, "oe"); }

	/* z\/ */
	else if (number==158)       { set_char(s, 'z'); }
	else if (number==382)       { set_char(s, 'z'); }

	/* Latin Capital Letter Y With Diaeresis  */
	else if (number==159)       { set_char(s, 'Y'); }
 	else if CMP("&Yuml;", s)    { set_char(s, 'Y'); }
	else if (number==376)       { set_char(s, 'Y'); }

	else { return(0); }

	return(1); /* Microsoft entity found */
}

/* ------------------------------------------------ */

void microsoft_character(int c)
{
	switch (c)
	{
		/* Microsoft... */
		case 0x80: /* MICROSOFT EURO */
			WORT_PLUS_STRING("EUR"); break;
		case 0x82: /* SINGLE LOW-9 QUOTATION MARK */
			wort_plus_ch(','); break;
		case 0x83: /* Latin Small Letter F With Hook */
			wort_plus_ch('f'); break;
		case 0x84: /* Double Low-9 Quotation Mark */
			WORT_PLUS_STRING("\""); break;
		case 0x85: /* HORIZONTAL ELLIPSIS */
			WORT_PLUS_STRING("..."); break;
		case 0x86: /* Dagger */
			WORT_PLUS_STRING("/-"); break;
		case 0x87: /* Double Dagger */
			WORT_PLUS_STRING("/="); break;
		case 0x88: /* Modifier Letter Circumflex Accent */
			wort_plus_ch('^'); break;
		case 0x89: /* Per Mille Sign */
			WORT_PLUS_STRING("0/00"); break;
		case 0x8a: /* Latin Capital Letter S With Caron */
			wort_plus_ch('S'); break;
		case 0x8b: /*  Single Left-Pointing Angle Quotation Mark */
			wort_plus_ch('<'); break;
		case 0x8c: /* Latin Capital Ligature OE */
			WORT_PLUS_STRING("OE"); break;
		case 0x8e: /* Z\/ */
			wort_plus_ch('Z'); break;
		case 0x91: /* LEFT SINGLE QUOTATION MARK */
			wort_plus_ch('`'); break;
		case 0x92: /* RIGHT SINGLE QUOTATION MARK */
			wort_plus_ch('\''); break;
		case 0x93: /* LEFT DOUBLE QUOTATION MARK */
			wort_plus_ch('\"'); break;
		case 0x94: /* RIGHT DOUBLE QUOTATION MARK */
			wort_plus_ch('\"'); break;
		case 0x95: /* BULLET */
			wort_plus_ch('*'); break;
		case 0x96: /* EN DASH */
			wort_plus_ch('-'); break;
		case 0x97: /* EM DASH */
			WORT_PLUS_STRING("--"); break;
		case 0x98: /* SMALL TILDE */
			wort_plus_ch('~'); break;
		case 0x99: /* TRADE MARK SIGN */
			WORT_PLUS_STRING("[tm]"); break;
		case 0x9a: /* LATIN SMALL LETTER S WITH CARON */
			wort_plus_ch('s'); break;
		case 0x9b: /* SINGLE RIGHT-POINTING ANGLE QUOTATION MARK */
			wort_plus_ch('>'); break;
		case 0x9c: /* LATIN SMALL LIGATURE OE */
			WORT_PLUS_STRING("oe"); break;
		case 0x9e: /* z\/ */
			wort_plus_ch('z'); break;
		case 0x9f: /* LATIN CAPITAL LETTER Y WITH DIAERESIS */
			wort_plus_ch('Y'); break;
	}
}
