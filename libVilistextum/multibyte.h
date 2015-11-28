#include <wchar.h>
#define CHAR wchar_t
#define STRLEN(s) wcslen(s)
#define CPYSS(dest, src) wcscpy(dest, src) /* copy str to str */
#define CPYSL(dest, src) wcscpy(dest, L##src) /* copy str to L"str" */

#define STRCMP(s1, s2)  wcscmp( L##s1, s2 )
#define STRCASECMP(s1, s2)  (wcscasecmp(L##s1, s2)==0)
#define CMP(s1, s2) (wcscmp(L##s1, s2)==0)
#define STRCAT(dest, src) wcscat(dest, (wchar_t*) src)

#define wcstoi(tmp)  wcstol(tmp, (wchar_t **)NULL, 10)
#define ATOI(n) wcstoi(n)

#define ONESPACE L" "
#define WORT_PLUS_STRING(str) wort_plus_string(L##str)

#define STRSTR(haystack, needle) wcsstr(haystack, L##needle)

#define STRNCMP(str1, str2, nr) wcsncmp(L##str1, str2, nr)

#define STRING(string) L##string

#define GETC(stream) fgetwc(stream)
#define CEOF WEOF

