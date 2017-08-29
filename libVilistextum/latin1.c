/*
 * Copyright (c) 1998-2006 Patric Müller
 * bhaak@gmx.net
 * http://bhaak.dyndns.org/vilistextum/
 *
 * Released under the GNU GPL Version 2 - http://www.gnu.org/copyleft/gpl.html
 *
 */

/*  History:
 *  18.04.01: now ignores entities for ascii control characters (0-31)
 *  19.04.01: added parse_entities(char *)
 *  03.09.01: added hexadecimal entities
 *  18.02.02: made tmpstr global. Amiga gcc 2.95 has problem with accessing it as local variable.
 *  16.10.02: entity number > 255 was not handled for multibyte
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>

#include "latin1.h"
#include "text.h"
#include "util.h"
#include "vilistextum.h"
#include "microsoft.h"
#include "unicode_entities.h"
#include "charset.h"

#include "multibyte.h"

int entity_number(CHAR *s);
int html_entity(CHAR*);
int latin1(CHAR*);

CHAR tmpstr[DEF_STR_LEN];

/* ------------------------------------------------ */

int set_char_wrapper(CHAR *str, int num)
{
	return(convert_character(num, str));
}

/* ------------------------------------------------ */

/* parse entity in string  */
void parse_entity(CHAR *str)
{
	int len = STRLEN(str);
	CPYSS(tmpstr, str);

	if (tmpstr[len-1]!=';') {
		tmpstr[len]   = ';';
		tmpstr[len+1] = '\0';
	}

	if (	entity_number(tmpstr) ||
		html_entity(tmpstr) ||
		latin1(tmpstr) ||
		microsoft_entities(tmpstr) ||
		unicode_entity(tmpstr) ||
		ligature_entity(tmpstr))
	{
		/* if true entity was known */
		CPYSS(str, tmpstr);
	}
}

/* ------------------------------------------------ */

/* parses entities in string */
void parse_entities(CHAR *s)
{
	int i=0,j=0,k=0;
	CHAR tmp[DEF_STR_LEN];
	CHAR entity[DEF_STR_LEN];
	int len=STRLEN(s);
	CHAR result[DEF_STR_LEN];

	if (len>=DEF_STR_LEN) { len = DEF_STR_LEN-1; }
	result[0] = '\0';

	while(i<=len) {
		j=0;
		while((s[i]!='\0') && (s[i]!='&') && (i<DEF_STR_LEN)) {
			tmp[j++] = s[i++];
		}
		tmp[j] = '\0';
		STRCAT(result, tmp);

		if (s[i]=='&') {
			k=0;
			while((s[i]!='\0') && (s[i]!=';') && (!isspace(s[i])) && (i<DEF_STR_LEN)) {
				entity[k++] = s[i++];
			}
			entity[k] = '\0';
			parse_entity(entity);

			STRCAT(result, entity);
		}
		i++;
	}

	CPYSS(s, result);
}

/* ------------------------------------------------ */

int entity_number(CHAR *s)
{
	int number;

	number = extract_entity_number(s);
	/* printf("entity_number: %d\n", number); */

	/* no numeric entity */
	if (number==-1) {
		return(0);
	} else {
		/* ascii printable character 32-127  */
		if ((number>=32) && (number<=127)) {
			return(convert_character(number, s));
		}
		/* ansi printable character 160-255 */
		else if ((number>=160) && (number<=255)) {
			/* latin1 soft hyphen, just swallow it and return empty string */
			if (number==173) {
				s[0] = '\0';
				return(1);
			}
			return(convert_character(number, s));
		}
		/* ascii control character -> return empty string */
		else if ((number >= 0) && (number < 32)) {
			s[0] = '\0';
			return(1);
		}
		else if (number > 255) {
			return(convert_character(number, s));
		}
	}
	return(0);
}

/* ------------------------------------------------ */

int html_entity(CHAR *str)
{
	if CMP("&quot;",      str)    { return(set_char_wrapper(str, '"')); }
	else if CMP("&;",     str)    { return(set_char_wrapper(str, '&')); } /* for those brain damaged ones */
	else if CMP("&amp;",  str)    { return(set_char_wrapper(str, '&')); }
	else if CMP("&gt;",   str)    { return(set_char_wrapper(str, '>')); }
	else if CMP("&lt;",   str)    { return(set_char_wrapper(str, '<')); }
	else if CMP("&apos;", str)    { return(set_char_wrapper(str, '\'')); }
	else { return(0); } /* found no html entity */
}

/* ------------------------------------------------ */

/* returns true if str is a known entity and changes str to the printout */
int latin1(CHAR *str)
{
	if CMP("&nbsp;", str)         { return(set_char_wrapper(str, 160)); } /* no-break space  */
	else if CMP("&iexcl;", str)   { return(set_char_wrapper(str, 161)); } /* inverted exclamation mark  */
	else if CMP("&cent;", str)    { return(set_char_wrapper(str, 162)); } /* cent sign  */
	else if CMP("&pound;", str)   { return(set_char_wrapper(str, 163)); } /* pound sterling sign  */
	else if CMP("&curren;", str)  { return(set_char_wrapper(str, 164)); } /* general currency sign  */
	else if CMP("&yen;", str)     { return(set_char_wrapper(str, 165)); } /* yen sign  */
	else if CMP("&brvbar;", str)  { return(set_char_wrapper(str, 166)); } /* broken (vertical) bar  */
	else if CMP("&sect;", str)    { return(set_char_wrapper(str, 167)); } /* section sign  */
	else if CMP("&uml;", str)     { return(set_char_wrapper(str, 168)); } /* umlaut (dieresis)  */
	else if CMP("&copy;", str)    { return(set_char_wrapper(str, 169)); } /* copyright sign  */
	else if CMP("&ordf;", str)    { return(set_char_wrapper(str, 170)); } /* ordinal indicator, feminine  */
	else if CMP("&laquo;", str)   { return(set_char_wrapper(str, 171)); } /* angle quotation mark, left  */
	else if CMP("&not;", str)     { return(set_char_wrapper(str, 172)); } /* not sign  */
	else if CMP("&shy;", str)     { return(set_char_wrapper(str, '\0')); } /* soft hyphen, just swallow it */
	else if CMP("&reg;", str)     { return(set_char_wrapper(str, 174)); } /* registered sign  */
	else if CMP("&macr;", str)    { return(set_char_wrapper(str, 175)); } /* macron  */
	else if CMP("&deg;", str)     { return(set_char_wrapper(str, 176)); } /* degree sign  */
	else if CMP("&plusmn;", str)  { return(set_char_wrapper(str, 177)); } /* plus-or-minus sign  */
	else if CMP("&sup2;", str)    { return(set_char_wrapper(str, 178)); } /* superscript two  */
	else if CMP("&sup3;", str)    { return(set_char_wrapper(str, 179)); } /* superscript three  */
	else if CMP("&acute;", str)   { return(set_char_wrapper(str, 180)); } /* acute accent  */
	else if CMP("&micro;", str)   { return(set_char_wrapper(str, 181)); } /* micro sign  */
	else if CMP("&para;", str)    { return(set_char_wrapper(str, 182)); } /* pilcrow (paragraph sign)  */
	else if CMP("&middot;", str)  { return(set_char_wrapper(str, 183)); } /* middle dot  */
	else if CMP("&cedil;", str)   { return(set_char_wrapper(str, 184)); } /* cedilla  */
	else if CMP("&sup1;", str)    { return(set_char_wrapper(str, 185)); } /* superscript one  */
	else if CMP("&ordm;", str)    { return(set_char_wrapper(str, 186)); } /* ordinal indicator, masculine  */
	else if CMP("&raquo;", str)   { return(set_char_wrapper(str, 187)); } /* angle quotation mark, right  */
	else if CMP("&frac14;", str)  { return(set_char_wrapper(str, 188)); } /* fraction one-quarter  */
	else if CMP("&frac12;", str)  { return(set_char_wrapper(str, 189)); } /* fraction one-half  */
	else if CMP("&frac34;", str)  { return(set_char_wrapper(str, 190)); } /* fraction three-quarters  */
	else if CMP("&iquest;", str)  { return(set_char_wrapper(str, 191)); } /* inverted question mark  */
	else if CMP("&Agrave;", str)  { return(set_char_wrapper(str, 192)); } /* capital A, grave accent  */
	else if CMP("&Aacute;", str)  { return(set_char_wrapper(str, 193)); } /* capital A, acute accent  */
	else if CMP("&Acirc;", str)   { return(set_char_wrapper(str, 194)); } /* capital A, circumflex accent  */
	else if CMP("&Atilde;", str)  { return(set_char_wrapper(str, 195)); } /* capital A, tilde  */
	else if CMP("&Auml;", str)    { return(set_char_wrapper(str, 196)); } /* capital A, dieresis or umlaut mark  */
	else if CMP("&Aring;", str)   { return(set_char_wrapper(str, 197)); } /* capital A, ring  */
	else if CMP("&AElig;", str)   { return(set_char_wrapper(str, 198)); } /* capital AE diphthong (ligature)  */
	else if CMP("&Ccedil;", str)  { return(set_char_wrapper(str, 199)); } /* capital C, cedilla  */
	else if CMP("&Egrave;", str)  { return(set_char_wrapper(str, 200)); } /* capital E, grave accent  */
	else if CMP("&Eacute;", str)  { return(set_char_wrapper(str, 201)); } /* capital E, acute accent  */
	else if CMP("&Ecirc;", str)   { return(set_char_wrapper(str, 202)); } /* capital E, circumflex accent  */
	else if CMP("&Euml;", str)    { return(set_char_wrapper(str, 203)); } /* capital E, dieresis or umlaut mark  */
	else if CMP("&Igrave;", str)  { return(set_char_wrapper(str, 204)); } /* capital I, grave accent  */
	else if CMP("&Iacute;", str)  { return(set_char_wrapper(str, 205)); } /* capital I, acute accent  */
	else if CMP("&Icirc;", str)   { return(set_char_wrapper(str, 206)); } /* capital I, circumflex accent  */
	else if CMP("&Iuml;", str)    { return(set_char_wrapper(str, 207)); } /* capital I, dieresis or umlaut mark  */
	else if CMP("&ETH;", str)     { return(set_char_wrapper(str, 208)); } /* capital Eth, Icelandic  */
	else if CMP("&Ntilde;", str)  { return(set_char_wrapper(str, 209)); } /* capital N, tilde  */
	else if CMP("&Ograve;", str)  { return(set_char_wrapper(str, 210)); } /* capital O, grave accent  */
	else if CMP("&Oacute;", str)  { return(set_char_wrapper(str, 211)); } /* capital O, acute accent  */
	else if CMP("&Ocirc;", str)   { return(set_char_wrapper(str, 212)); } /* capital O, circumflex accent  */
	else if CMP("&Otilde;", str)  { return(set_char_wrapper(str, 213)); } /* capital O, tilde  */
	else if CMP("&Ouml;", str)    { return(set_char_wrapper(str, 214)); } /* capital O, dieresis or umlaut mark  */
	else if CMP("&times;", str)   { return(set_char_wrapper(str, 215)); } /* multiply sign  */
	else if CMP("&Oslash;", str)  { return(set_char_wrapper(str, 216)); } /* capital O, slash  */
	else if CMP("&Ugrave;", str)  { return(set_char_wrapper(str, 217)); } /* capital U, grave accent  */
	else if CMP("&Uacute;", str)  { return(set_char_wrapper(str, 218)); } /* capital U, acute accent  */
	else if CMP("&Ucirc;", str)   { return(set_char_wrapper(str, 219)); } /* capital U, circumflex accent  */
	else if CMP("&Uuml;", str)    { return(set_char_wrapper(str, 220)); } /* capital U, dieresis or umlaut mark  */
	else if CMP("&Yacute;", str)  { return(set_char_wrapper(str, 221)); } /* capital Y, acute accent  */
	else if CMP("&THORN;", str)   { return(set_char_wrapper(str, 222)); } /* capital THORN, Icelandic  */
	else if CMP("&szlig;", str)   { return(set_char_wrapper(str, 223)); } /* small sharp s, German (sz ligature)  */
	else if CMP("&agrave;", str)  { return(set_char_wrapper(str, 224)); } /* small a, grave accent  */
	else if CMP("&aacute;", str)  { return(set_char_wrapper(str, 225)); } /* small a, acute accent  */
	else if CMP("&acirc;", str)   { return(set_char_wrapper(str, 226)); } /* small a, circumflex accent  */
	else if CMP("&atilde;", str)  { return(set_char_wrapper(str, 227)); } /* small a, tilde  */
	else if CMP("&auml;", str)    { return(set_char_wrapper(str, 228)); } /* small a, dieresis or umlaut mark  */
	else if CMP("&aring;", str)   { return(set_char_wrapper(str, 229)); } /* small a, ring  */
	else if CMP("&aelig;", str)   { return(set_char_wrapper(str, 230)); } /* small ae diphthong (ligature)  */
	else if CMP("&ccedil;", str)  { return(set_char_wrapper(str, 231)); } /* small c, cedilla  */
	else if CMP("&egrave;", str)  { return(set_char_wrapper(str, 232)); } /* small e, grave accent  */
	else if CMP("&eacute;", str)  { return(set_char_wrapper(str, 233)); } /* small e, acute accent  */
	else if CMP("&ecirc;", str)   { return(set_char_wrapper(str, 234)); } /* small e, circumflex accent  */
	else if CMP("&euml;", str)    { return(set_char_wrapper(str, 235)); } /* small e, dieresis or umlaut mark  */
	else if CMP("&igrave;", str)  { return(set_char_wrapper(str, 236)); } /* small i, grave accent  */
	else if CMP("&iacute;", str)  { return(set_char_wrapper(str, 237)); } /* small i, acute accent  */
	else if CMP("&icirc;", str)   { return(set_char_wrapper(str, 238)); } /* small i, circumflex accent  */
	else if CMP("&iuml;", str)    { return(set_char_wrapper(str, 239)); } /* small i, dieresis or umlaut mark  */
	else if CMP("&eth;", str)     { return(set_char_wrapper(str, 240)); } /* small eth, Icelandic  */
	else if CMP("&ntilde;", str)  { return(set_char_wrapper(str, 241)); } /* small n, tilde  */
	else if CMP("&ograve;", str)  { return(set_char_wrapper(str, 242)); } /* small o, grave accent  */
	else if CMP("&oacute;", str)  { return(set_char_wrapper(str, 243)); } /* small o, acute accent  */
	else if CMP("&ocirc;", str)   { return(set_char_wrapper(str, 244)); } /* small o, circumflex accent  */
	else if CMP("&otilde;", str)  { return(set_char_wrapper(str, 245)); } /* small o, tilde  */
	else if CMP("&ouml;", str)    { return(set_char_wrapper(str, 246)); } /* small o, dieresis or umlaut mark  */
	else if CMP("&divide;", str)  { return(set_char_wrapper(str, 247)); } /* divide sign  */
	else if CMP("&oslash;", str)  { return(set_char_wrapper(str, 248)); } /* small o, slash  */
	else if CMP("&ugrave;", str)  { return(set_char_wrapper(str, 249)); } /* small u, grave accent  */
	else if CMP("&uacute;", str)  { return(set_char_wrapper(str, 250)); } /* small u, acute accent  */
	else if CMP("&ucirc;", str)   { return(set_char_wrapper(str, 251)); } /* small u, circumflex accent  */
	else if CMP("&uuml;", str)    { return(set_char_wrapper(str, 252)); } /* small u, dieresis or umlaut mark  */
	else if CMP("&yacute;", str)  { return(set_char_wrapper(str, 253)); } /* small y, acute accent  */
	else if CMP("&thorn;", str)   { return(set_char_wrapper(str, 254)); } /* small thorn, Icelandic  */
	else if CMP("&yuml;", str)    { return(set_char_wrapper(str, 255)); } /* small y, dieresis or umlaut mark  */
	else if CMP("&fnof;", str)     { return(set_char_wrapper(str,  402)); }
	else if CMP("&Alpha;", str)    { return(set_char_wrapper(str,  913)); }
	else if CMP("&Beta;", str)     { return(set_char_wrapper(str,  914)); }
	else if CMP("&Gamma;", str)    { return(set_char_wrapper(str,  915)); }
	else if CMP("&Delta;", str)    { return(set_char_wrapper(str,  916)); }
	else if CMP("&Epsilon;", str)  { return(set_char_wrapper(str,  917)); }
	else if CMP("&Zeta;", str)     { return(set_char_wrapper(str,  918)); }
	else if CMP("&Eta;", str)      { return(set_char_wrapper(str,  919)); }
	else if CMP("&Theta;", str)    { return(set_char_wrapper(str,  920)); }
	else if CMP("&Iota;", str)     { return(set_char_wrapper(str,  921)); }
	else if CMP("&Kappa;", str)    { return(set_char_wrapper(str,  922)); }
	else if CMP("&Lambda;", str)   { return(set_char_wrapper(str,  923)); }
	else if CMP("&Mu;", str)       { return(set_char_wrapper(str,  924)); }
	else if CMP("&Nu;", str)       { return(set_char_wrapper(str,  925)); }
	else if CMP("&Xi;", str)       { return(set_char_wrapper(str,  926)); }
	else if CMP("&Omicron;", str)  { return(set_char_wrapper(str,  927)); }
	else if CMP("&Pi;", str)       { return(set_char_wrapper(str,  928)); }
	else if CMP("&Rho;", str)      { return(set_char_wrapper(str,  929)); }
	else if CMP("&Sigma;", str)    { return(set_char_wrapper(str,  931)); }
	else if CMP("&Tau;", str)      { return(set_char_wrapper(str,  932)); }
	else if CMP("&Upsilon;", str)  { return(set_char_wrapper(str,  933)); }
	else if CMP("&Phi;", str)      { return(set_char_wrapper(str,  934)); }
	else if CMP("&Chi;", str)      { return(set_char_wrapper(str,  935)); }
	else if CMP("&Psi;", str)      { return(set_char_wrapper(str,  936)); }
	else if CMP("&Omega;", str)    { return(set_char_wrapper(str,  937)); }
	else if CMP("&alpha;", str)    { return(set_char_wrapper(str,  945)); }
	else if CMP("&beta;", str)     { return(set_char_wrapper(str,  946)); }
	else if CMP("&gamma;", str)    { return(set_char_wrapper(str,  947)); }
	else if CMP("&delta;", str)    { return(set_char_wrapper(str,  948)); }
	else if CMP("&epsilon;", str)  { return(set_char_wrapper(str,  949)); }
	else if CMP("&zeta;", str)     { return(set_char_wrapper(str,  950)); }
	else if CMP("&eta;", str)      { return(set_char_wrapper(str,  951)); }
	else if CMP("&theta;", str)    { return(set_char_wrapper(str,  952)); }
	else if CMP("&iota;", str)     { return(set_char_wrapper(str,  953)); }
	else if CMP("&kappa;", str)    { return(set_char_wrapper(str,  954)); }
	else if CMP("&lambda;", str)   { return(set_char_wrapper(str,  955)); }
	else if CMP("&mu;", str)       { return(set_char_wrapper(str,  956)); }
	else if CMP("&nu;", str)       { return(set_char_wrapper(str,  957)); }
	else if CMP("&xi;", str)       { return(set_char_wrapper(str,  958)); }
	else if CMP("&omicron;", str)  { return(set_char_wrapper(str,  959)); }
	else if CMP("&pi;", str)       { return(set_char_wrapper(str,  960)); }
	else if CMP("&rho;", str)      { return(set_char_wrapper(str,  961)); }
	else if CMP("&sigmaf;", str)   { return(set_char_wrapper(str,  962)); }
	else if CMP("&sigma;", str)    { return(set_char_wrapper(str,  963)); }
	else if CMP("&tau;", str)      { return(set_char_wrapper(str,  964)); }
	else if CMP("&upsilon;", str)  { return(set_char_wrapper(str,  965)); }
	else if CMP("&phi;", str)      { return(set_char_wrapper(str,  966)); }
	else if CMP("&chi;", str)      { return(set_char_wrapper(str,  967)); }
	else if CMP("&psi;", str)      { return(set_char_wrapper(str,  968)); }
	else if CMP("&omega;", str)    { return(set_char_wrapper(str,  969)); }
	else if CMP("&thetasym;", str) { return(set_char_wrapper(str,  977)); }
	else if CMP("&upsih;", str)    { return(set_char_wrapper(str,  978)); }
	else if CMP("&piv;", str)      { return(set_char_wrapper(str,  982)); }
	else if CMP("&bull;", str)     { return(set_char_wrapper(str,  8226)); }
	else if CMP("&hellip;", str)   { return(set_char_wrapper(str,  8230)); }
	else if CMP("&prime;", str)    { return(set_char_wrapper(str,  8242)); }
	else if CMP("&Prime;", str)    { return(set_char_wrapper(str,  8243)); }
	else if CMP("&oline;", str)    { return(set_char_wrapper(str,  8254)); }
	else if CMP("&frasl;", str)    { return(set_char_wrapper(str,  8260)); }
	else if CMP("&weierp;", str)   { return(set_char_wrapper(str,  8472)); }
	else if CMP("&image;", str)    { return(set_char_wrapper(str,  8465)); }
	else if CMP("&real;", str)     { return(set_char_wrapper(str,  8476)); }
	else if CMP("&trade;", str)    { return(set_char_wrapper(str,  8482)); }
	else if CMP("&alefsym;", str)  { return(set_char_wrapper(str,  8501)); }
	else if CMP("&larr;", str)     { return(set_char_wrapper(str,  8592)); }
	else if CMP("&uarr;", str)     { return(set_char_wrapper(str,  8593)); }
	else if CMP("&rarr;", str)     { return(set_char_wrapper(str,  8594)); }
	else if CMP("&darr;", str)     { return(set_char_wrapper(str,  8595)); }
	else if CMP("&harr;", str)     { return(set_char_wrapper(str,  8596)); }
	else if CMP("&crarr;", str)    { return(set_char_wrapper(str,  8629)); }
	else if CMP("&lArr;", str)     { return(set_char_wrapper(str,  8656)); }
	else if CMP("&uArr;", str)     { return(set_char_wrapper(str,  8657)); }
	else if CMP("&rArr;", str)     { return(set_char_wrapper(str,  8658)); }
	else if CMP("&dArr;", str)     { return(set_char_wrapper(str,  8659)); }
	else if CMP("&hArr;", str)     { return(set_char_wrapper(str,  8660)); }
	else if CMP("&forall;", str)   { return(set_char_wrapper(str,  8704)); }
	else if CMP("&part;", str)     { return(set_char_wrapper(str,  8706)); }
	else if CMP("&exist;", str)    { return(set_char_wrapper(str,  8707)); }
	else if CMP("&empty;", str)    { return(set_char_wrapper(str,  8709)); }
	else if CMP("&nabla;", str)    { return(set_char_wrapper(str,  8711)); }
	else if CMP("&isin;", str)     { return(set_char_wrapper(str,  8712)); }
	else if CMP("&notin;", str)    { return(set_char_wrapper(str,  8713)); }
	else if CMP("&ni;", str)       { return(set_char_wrapper(str,  8715)); }
	else if CMP("&prod;", str)     { return(set_char_wrapper(str,  8719)); }
	else if CMP("&sum;", str)      { return(set_char_wrapper(str,  8721)); }
	else if CMP("&minus;", str)    { return(set_char_wrapper(str,  8722)); }
	else if CMP("&lowast;", str)   { return(set_char_wrapper(str,  8727)); }
	else if CMP("&radic;", str)    { return(set_char_wrapper(str,  8730)); }
	else if CMP("&prop;", str)     { return(set_char_wrapper(str,  8733)); }
	else if CMP("&infin;", str)    { return(set_char_wrapper(str,  8734)); }
	else if CMP("&ang;", str)      { return(set_char_wrapper(str,  8736)); }
	else if CMP("&and;", str)      { return(set_char_wrapper(str,  8743)); }
	else if CMP("&or;", str)       { return(set_char_wrapper(str,  8744)); }
	else if CMP("&cap;", str)      { return(set_char_wrapper(str,  8745)); }
	else if CMP("&cup;", str)      { return(set_char_wrapper(str,  8746)); }
	else if CMP("&int;", str)      { return(set_char_wrapper(str,  8747)); }
	else if CMP("&there4;", str)   { return(set_char_wrapper(str,  8756)); }
	else if CMP("&sim;", str)      { return(set_char_wrapper(str,  8764)); }
	else if CMP("&cong;", str)     { return(set_char_wrapper(str,  8773)); }
	else if CMP("&asymp;", str)    { return(set_char_wrapper(str,  8776)); }
	else if CMP("&ne;", str)       { return(set_char_wrapper(str,  8800)); }
	else if CMP("&equiv;", str)    { return(set_char_wrapper(str,  8801)); }
	else if CMP("&le;", str)       { return(set_char_wrapper(str,  8804)); }
	else if CMP("&ge;", str)       { return(set_char_wrapper(str,  8805)); }
	else if CMP("&sub;", str)      { return(set_char_wrapper(str,  8834)); }
	else if CMP("&sup;", str)      { return(set_char_wrapper(str,  8835)); }
	else if CMP("&nsub;", str)     { return(set_char_wrapper(str,  8836)); }
	else if CMP("&sube;", str)     { return(set_char_wrapper(str,  8838)); }
	else if CMP("&supe;", str)     { return(set_char_wrapper(str,  8839)); }
	else if CMP("&oplus;", str)    { return(set_char_wrapper(str,  8853)); }
	else if CMP("&otimes;", str)   { return(set_char_wrapper(str,  8855)); }
	else if CMP("&perp;", str)     { return(set_char_wrapper(str,  8869)); }
	else if CMP("&sdot;", str)     { return(set_char_wrapper(str,  8901)); }
	else if CMP("&lceil;", str)    { return(set_char_wrapper(str,  8968)); }
	else if CMP("&rceil;", str)    { return(set_char_wrapper(str,  8969)); }
	else if CMP("&lfloor;", str)   { return(set_char_wrapper(str,  8970)); }
	else if CMP("&rfloor;", str)   { return(set_char_wrapper(str,  8971)); }
	else if CMP("&lang;", str)     { return(set_char_wrapper(str,  9001)); }
	else if CMP("&rang;", str)     { return(set_char_wrapper(str,  9002)); }
 	else if CMP("&loz;", str)      { return(set_char_wrapper(str,  9674)); }
	else if CMP("&spades;", str)   { return(set_char_wrapper(str,  9824)); }
	else if CMP("&clubs;", str)    { return(set_char_wrapper(str,  9827)); }
	else if CMP("&hearts;", str)   { return(set_char_wrapper(str,  9829)); }
	else if CMP("&diams;", str)    { return(set_char_wrapper(str,  9830)); }
	else if CMP("&quot;", str)     { return(set_char_wrapper(str,  34)); }
	else if CMP("&amp;", str)      { return(set_char_wrapper(str,  38)); }
	else if CMP("&apos;", str)     { return(set_char_wrapper(str,  39)); }
	else if CMP("&lt;", str)       { return(set_char_wrapper(str,  60)); }
	else if CMP("&gt;", str)       { return(set_char_wrapper(str,  62)); }
	else if CMP("&OElig;", str)    { return(set_char_wrapper(str,  338)); }
	else if CMP("&oelig;", str)    { return(set_char_wrapper(str,  339)); }
	else if CMP("&Scaron;", str)   { return(set_char_wrapper(str,  352)); }
	else if CMP("&scaron;", str)   { return(set_char_wrapper(str,  353)); }
	else if CMP("&Yuml;", str)     { return(set_char_wrapper(str,  376)); }
	else if CMP("&circ;", str)     { return(set_char_wrapper(str,  710)); }
	else if CMP("&tilde;", str)    { return(set_char_wrapper(str,  732)); }
  	else if CMP("&ensp;", str)     { return(set_char_wrapper(str,  8194)); }
	else if CMP("&emsp;", str)     { return(set_char_wrapper(str,  8195)); }
	else if CMP("&thinsp;", str)   { return(set_char_wrapper(str,  8201)); }
	else if CMP("&zwnj;", str)     { return(set_char_wrapper(str,  8204)); }
	else if CMP("&zwj;", str)      { return(set_char_wrapper(str,  8205)); }
	else if CMP("&lrm;", str)      { return(set_char_wrapper(str,  8206)); }
	else if CMP("&rlm;", str)      { return(set_char_wrapper(str,  8207)); }
	else if CMP("&ndash;", str)    { return(set_char_wrapper(str,  8211)); }
	else if CMP("&mdash;", str)    { return(set_char_wrapper(str,  8212)); }
	else if CMP("&lsquo;", str)    { return(set_char_wrapper(str,  8216)); }
	else if CMP("&rsquo;", str)    { return(set_char_wrapper(str,  8217)); }
	else if CMP("&sbquo;", str)    { return(set_char_wrapper(str,  8218)); }
	else if CMP("&ldquo;", str)    { return(set_char_wrapper(str,  8220)); }
	else if CMP("&rdquo;", str)    { return(set_char_wrapper(str,  8221)); }
	else if CMP("&bdquo;", str)    { return(set_char_wrapper(str,  8222)); }
	else if CMP("&dagger;", str)   { return(set_char_wrapper(str,  8224)); }
	else if CMP("&Dagger;", str)   { return(set_char_wrapper(str,  8225)); }
	else if CMP("&permil;", str)   { return(set_char_wrapper(str,  8240)); }
	else if CMP("&lsaquo;", str)   { return(set_char_wrapper(str,  8249)); }
	else if CMP("&rsaquo;", str)   { return(set_char_wrapper(str,  8250)); }
	else if CMP("&euro;", str)     { return(set_char_wrapper(str,  8364)); }
  	else { return(0); }  /* found no latin1 entity */

  	return(1); /* found latin1 entity  */
}
