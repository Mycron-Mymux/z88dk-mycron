#include <stdio.h>
#include <mycron.h>
#include <mycron_disk.h>

static unsigned char sector[128];

int main(void)
{
    unsigned char st;
    mycron_sector_io_t p;

    p.unit = 0;
    p.track = 0;
    p.sector = 7;
    p.bad74 = 0;
    p.bad75 = 0;
    p.addr = sector;

    st = mycron_bdo(0);
    printf("BDO(0) = %u\n", st);

    if (st == MYCRON_DSK_OK) {
        printf("trying sector read\n");
        st = mycron_bldr(&p);
        printf(" - read return = %u\n", st); 
    }

    st = mycron_bdc(0);
    printf("BDC(0) = %u\n", st);

    mycron_exit_to_monitor();
    return 0;
}
