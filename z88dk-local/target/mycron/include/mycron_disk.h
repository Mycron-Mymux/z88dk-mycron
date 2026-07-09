#ifndef MYCRON_DISK_H
#define MYCRON_DISK_H

#ifdef __cplusplus
extern "C" {
#endif

/*
 * MYCROP disk status codes, according to the monitor documentation.
 */
#define MYCRON_DSK_OK              0
#define MYCRON_DSK_CRC_DATA        1
#define MYCRON_DSK_UNIT_NOT_READY  2
#define MYCRON_DSK_DELETED_DATA    3
#define MYCRON_DSK_INVALID_TRACK   4
#define MYCRON_DSK_INVALID_SECTOR  5
#define MYCRON_DSK_INVALID_UNIT    6
#define MYCRON_DSK_CRC_HEADER      7
#define MYCRON_DSK_MISSING_DATA_AM 8

/*
 * Raw sector I/O parameter block.
 *
 * BLDR/BUDR:
 *
 *   unit   = disk unit 0..7
 *   track  = track number
 *   sector = sector number, normally 1..26
 *   bad74  = bad track replacement value for track 74, normally 0
 *   bad75  = bad track replacement value for track 75, normally 0
 *   addr   = memory address of 128-byte buffer
 */
typedef struct mycron_sector_io {
    unsigned char unit;
    unsigned char track;
    unsigned char sector;
    unsigned char bad74;
    unsigned char bad75;
    void *addr;
} mycron_sector_io_t;

/*
 * MYCROP LOAD/LINK parameter block.
 *
 * name8 must point to an 8-byte, space-padded program name.
 *
 * On successful mycron_load(), entry is filled with the entry address
 * returned by MYCROP LOAD.
 */
typedef struct mycron_load_params {
    unsigned char unit;
    const char *name8;
    void *entry;
} mycron_load_params_t;


/*
 * Low-level monitor wrappers.
 *
 * These correspond closely to the MYCROP monitor calls.
 */
unsigned char mycron_bdo(unsigned char unit) __z88dk_fastcall;
unsigned char mycron_bdc(unsigned char unit) __z88dk_fastcall;
unsigned char mycron_bdd(unsigned char unit) __z88dk_fastcall;

unsigned char mycron_bldr(mycron_sector_io_t *p) __z88dk_fastcall;
unsigned char mycron_budr(mycron_sector_io_t *p) __z88dk_fastcall;
unsigned char mycron_brdr(mycron_sector_io_t *p) __z88dk_fastcall;
unsigned char mycron_bwdr(mycron_sector_io_t *p) __z88dk_fastcall;
unsigned char mycron_bddr(mycron_sector_io_t *p) __z88dk_fastcall;

unsigned char mycron_load(mycron_load_params_t *p) __z88dk_fastcall;
unsigned char mycron_link(mycron_load_params_t *p) __z88dk_fastcall;


/*
 * Convenience helpers.
 *
 * These call BDO, perform the operation, then call BDC.
 */
unsigned char mycron_disk_read_sector(
    unsigned char unit,
    unsigned char track,
    unsigned char sector,
    void *buffer
);

unsigned char mycron_disk_write_sector(
    unsigned char unit,
    unsigned char track,
    unsigned char sector,
    const void *buffer
);

/*
 * Convert a normal C string to an 8-byte MYCROP program name.
 *
 * Example:
 *
 *   char name[8];
 *   mycron_make_name8(name, "MSYSTEM");
 */
void mycron_make_name8(char dest[8], const char *src);

#ifdef __cplusplus
}
#endif

#endif
