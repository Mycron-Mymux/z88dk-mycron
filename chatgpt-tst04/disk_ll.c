#include <stdio.h>
#include <mycron.h>
#include <mycron_disk.h>

int main(void)
{
    unsigned char st;

    st = mycron_bdo(0);
    printf("BDO(0) = %u\n", st);

    st = mycron_bdc(0);
    printf("BDC(0) = %u\n", st);

    mycron_exit_to_monitor();
    return 0;
}
