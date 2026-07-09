#include <mycron_disk.h>

unsigned char mycron_disk_read_sector(
    unsigned char unit,
    unsigned char track,
    unsigned char sector,
    void *buffer
)
{
    unsigned char st;
    mycron_sector_io_t p;

    p.unit = unit;
    p.track = track;
    p.sector = sector;
    p.bad74 = 0;
    p.bad75 = 0;
    p.addr = buffer;

    st = mycron_bdo(unit);
    if (st != MYCRON_DSK_OK) {
        return st;
    }

    st = mycron_bldr(&p);

    /*
     * Try to close even if the read failed.
     * Preserve the original operation status.
     */
    mycron_bdc(unit);

    return st;
}
