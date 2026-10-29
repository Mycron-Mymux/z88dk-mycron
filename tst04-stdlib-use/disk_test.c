#include <stdio.h>
#include <mycron.h>
#include <mycron_disk.h>

static unsigned char sector[128];

int main(void)
{
    unsigned char st;
    unsigned int i;

    printf("Mycron disk test\n");

    /*
     * Read track 0, sector 7 from unit 0.
     *
     * According to your LOAD disassembly, sector 7 is special
     * for the program directory/signature area, so it is a useful
     * low-level read test.
     */
    st = mycron_disk_read_sector(0, 0, 7, sector);

    printf("read status = %u\n", st);

    if (st == MYCRON_DSK_OK) {
        for (i = 0; i < 16; ++i) {
            printf("%02x ", sector[i]);
        }
        printf("\n");
    }

    mycron_exit_to_monitor();
    return 0;
}

