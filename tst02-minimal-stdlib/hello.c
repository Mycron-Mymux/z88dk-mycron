#include "mycron.h"

int main(void)
{
    int ch;
    mycron_di();
#if 0
    mycron_putchar('=');
    mycron_putchar('>');
    mycron_putchar('\r');
    mycron_putchar('\n');
#endif
    mycron_puts_crlf("Hello from z88dk on Mycron!");
    mycron_puts_crlf("Press a key:");

    ch = mycron_getchar_echo();

    mycron_crlf();
    mycron_puts("You pressed: ");
    mycron_putchar((unsigned char)ch);
    mycron_crlf();

    mycron_puts_crlf("Returning to MYCROP monitor.");

    mycron_exit_to_monitor(); 
    while (1) {
    }

    return 0;
}

