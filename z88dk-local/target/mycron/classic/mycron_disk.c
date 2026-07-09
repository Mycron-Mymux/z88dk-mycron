#include <mycron_disk.h>

/*
 * Convert C string to MYCROP 8-char, space-padded name.
 *
 * Lowercase a-z is converted to uppercase.
 */
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
