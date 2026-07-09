#include <mycron_disk.h>

void mycron_make_name8(char dest[8], const char *src)
{
    unsigned char i;
    char c;

    for (i = 0; i < 8; ++i) {
        dest[i] = ' ';
    }

    for (i = 0; i < 8; ++i) {
        c = src[i];

        if (c == 0) {
            break;
        }

        if (c >= 'a' && c <= 'z') {
            c = (char)(c - 'a' + 'A');
        }

        dest[i] = c;
    }
}

