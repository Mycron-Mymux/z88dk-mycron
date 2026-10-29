#include <stdio.h>
#include <mycron.h>

int main(void)
{
    int c;

    printf("Hello from +mycron!\n");
    printf("Press a key: ");

    c = getchar();

    printf("\nYou pressed '%c' = %d = 0x%02x\n", c, c, c);
    printf("Returning to MYCROP monitor.\n");

    mycron_exit_to_monitor();

    return 0;
}
