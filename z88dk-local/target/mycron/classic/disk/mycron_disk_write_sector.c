#include <mycron_disk.h>

unsigned char mycron_disk_write_sector(
    unsigned char unit,
    unsigned char track,
    unsigned char sector,
    const void *buffer
)
{
    unsigned char st;
    mycron_sector_io_t p;

    p.unit = unit;
    p.track = track;
    p.sector = sector;
    p.bad74 = 0;
    p.bad75 = 0;
    p.addr = (void *)buffer;

    st = mycron_bdo(unit);
    if (st != MYCRON_DSK_OK) {
        return st;
    }

    st = mycron_budr(&p);

    /*
     * Try to close even if the write failed.
     * Preserve the original operation status.
     */
    mycron_bdc(unit);

    return st;
}

