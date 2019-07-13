#pragma once

/**
 * Strips HTML from the input string and returns just the text.
 * The resulting string must be freed when you're done with it.
 */
char *htmlclean_strip_html(const char *);
