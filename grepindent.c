/*
 * grepindent.c
 * 
 * This program reads from standard input and extracts a block of text that
 * matches a given keyword and continues printing lines with the same
 * or greater indentation level. It stops when a line with less indentation
 * is encountered.
 *
 * Compilation:
 * gcc -o grepindent grepindent.c
 * 
 * Installation:
 * sudo mv grepindent /usr/local/bin/
 * 
 * Usage:
 * sudo iw dev $(ip -o link show | awk -F': ' '{print $2}' | grep wl) scan | grepindent "60:b9"
 * 
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAX_LINE_LENGTH 1024

// Function to calculate the indentation level of a line
int get_indent_level(char *line) {
    int level = 0;
    while (*line == ' ' || *line == '\t') {
        if (*line == ' ')
            level++;
        else if (*line == '\t')
            level += 4; // Assuming a tab is 4 spaces
        line++;
    }
    return level;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <keyword>\n", argv[0]);
        return 1;
    }

    char *keyword = argv[1];
    char line[MAX_LINE_LENGTH];
    int initial_indent_level = -1;
    int matched = 0;

    // Read lines from standard input
    while (fgets(line, sizeof(line), stdin)) {
        int current_indent = get_indent_level(line);

        // Check if the line contains the keyword
        if (!matched && strstr(line, keyword)) {
            matched = 1;
            initial_indent_level = current_indent;
            printf("%s", line);  // Print the line with the keyword
        } else if (matched) {
            // Print lines with the same or greater indentation level
            if (current_indent <= initial_indent_level) {
                break;
            }
            printf("%s", line);
        }
    }

    return 0;
}
