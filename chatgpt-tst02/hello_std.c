#include <stdio.h>

void mycron_exit_to_monitor(void);

int main(void)
{
    int c;

    printf("Hello from standard C on Mycron!\n");
    printf("Press a key: ");

    c = getchar();

    printf("\nYou pressed '%c' = %d = 0x%02x\n", c, c, c);
    printf("Returning to MYCROP monitor.\n");

    mycron_exit_to_monitor();

    return 0;
}
