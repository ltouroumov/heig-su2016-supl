#include <cstdlib>
#include <cstdio>
#include <cstring>

#include "utils.hpp"

char* parse_str(char* raw_str)
{
    int len = strlen(raw_str);
    raw_str++; // skip first quote
    char* new_str = (char*)calloc(len, sizeof(char));

    char* str = new_str;
    while (*raw_str != '\0') {
        if (*raw_str == '\\') {
            switch(raw_str[1]) {
                case 'n':
                    *str = '\n';
                    raw_str++;
                    break;
                case 'r':
                    *str = '\r';
                    raw_str++;
                    break;
                case 't':
                    *str = '\t';
                    raw_str++;
                    break;
                default:
                    *str = *raw_str;
                    break;
            }
        } else {
            *str = *raw_str;
        }
        ++str;
        ++raw_str;
    }

    *(str - 1) = '\0';
    return new_str;
}