/* This is a CLI interface to libvilistextum to make it easier to run a fuzzer */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "vilistextum.h"

char* stdin_to_string()
{
	const int BUFFER_SIZE = 4096;
	char buffer[BUFFER_SIZE];
	size_t content_size = 1; // includes null
	char *content = malloc(sizeof(char) * BUFFER_SIZE);
	content[0] = '\0';
	while(fgets(buffer, BUFFER_SIZE, stdin))
	{
		content_size += strlen(buffer);
		content = realloc(content, content_size);
		strcat(content, buffer);
	}
	return content;
}

int main()
{
	char* content = stdin_to_string();
	free(vilistextum(content, 0));
	free(vilistextum(content, 1));
	free(content);
	return 0;
}
