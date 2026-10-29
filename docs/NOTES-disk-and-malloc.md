Great. Those are good next targets.

I would split this into three small target-support files:

```text
z88dk-local/target/mycron/include/mycron_disk.h
z88dk-local/target/mycron/include/mycron_alloc.h
z88dk-local/target/mycron/classic/mycron_disk.asm
z88dk-local/target/mycron/classic/mycron_disk.c
z88dk-local/target/mycron/classic/mycron_alloc.c
```

Then add these target-support files to your `CLIB classic` line in `mycron.cfg`, the same way you added `mycron_stdio.asm`.

---

# 1. MYCROP disk function wrappers

The MYCROP disk functions are low-level sector/program-loader routines. These wrappers expose them cleanly to C.

## Disk monitor calls used

From your PROM:

```asm
LOAD  006Dh
BDO   0070h
BRDR  0073h
BWDR  0076h
BDDR  0079h
BDC   007Ch
BDD   007Fh
BLDR  0082h
BUDR  0085h
LINK  0088h
```

The most immediately useful ones are:

| Function | Meaning |
|---|---|
| `BDO` | open disk / head down / seek track 0 |
| `BDC` | close disk / head up |
| `BLDR` | read raw 128-byte sector |
| `BUDR` | write raw 128-byte sector |
| `LOAD` | load named MYCROP program |
| `LINK` | load and start named MYCROP program |

---

# 2. `mycron_disk.h`

Create:

```c
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
```

---

# 3. `mycron_disk.asm`

Create:

```asm
; mycron_disk.asm
;
; C wrappers for MYCROP disk services.
;
; These are low-level monitor wrappers. Higher-level convenience
; functions are implemented in mycron_disk.c.
;
; z88dk/sccz80 C symbols have leading underscores.
;
; Functions using __z88dk_fastcall receive their single argument in HL.

        MODULE  mycron_disk

        SECTION code_clib

        defc    MYCROP_LOAD     = 006Dh
        defc    MYCROP_BDO      = 0070h
        defc    MYCROP_BRDR     = 0073h
        defc    MYCROP_BWDR     = 0076h
        defc    MYCROP_BDDR     = 0079h
        defc    MYCROP_BDC      = 007Ch
        defc    MYCROP_BDD      = 007Fh
        defc    MYCROP_BLDR     = 0082h
        defc    MYCROP_BUDR     = 0085h
        defc    MYCROP_LINK     = 0088h

        PUBLIC  _mycron_bdo
        PUBLIC  _mycron_bdc
        PUBLIC  _mycron_bdd

        PUBLIC  _mycron_bldr
        PUBLIC  _mycron_budr
        PUBLIC  _mycron_brdr
        PUBLIC  _mycron_bwdr
        PUBLIC  _mycron_bddr

        PUBLIC  _mycron_load
        PUBLIC  _mycron_link


; ------------------------------------------------------------
; unsigned char mycron_bdo(unsigned char unit) __z88dk_fastcall;
;
; L = unit
; returns status in HL
; ------------------------------------------------------------

_mycron_bdo:
        ld      a,l
        call    MYCROP_BDO
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; unsigned char mycron_bdc(unsigned char unit) __z88dk_fastcall;
; ------------------------------------------------------------

_mycron_bdc:
        ld      a,l
        call    MYCROP_BDC
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; unsigned char mycron_bdd(unsigned char unit) __z88dk_fastcall;
; ------------------------------------------------------------

_mycron_bdd:
        ld      a,l
        call    MYCROP_BDD
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; Common setup for sector I/O parameter block.
;
; Input:
;   HL = pointer to mycron_sector_io_t
;
; Output:
;   A  = unit
;   B  = track
;   C  = sector
;   D  = bad74
;   E  = bad75
;   HL = buffer address
;
; Struct layout:
;   +0 unit
;   +1 track
;   +2 sector
;   +3 bad74
;   +4 bad75
;   +5 addr low
;   +6 addr high
; ------------------------------------------------------------

mycron_disk_setup_sector_params:
        push    ix
        push    hl
        pop     ix

        ld      a,(ix+0)
        ld      b,(ix+1)
        ld      c,(ix+2)
        ld      d,(ix+3)
        ld      e,(ix+4)
        ld      l,(ix+5)
        ld      h,(ix+6)

        pop     ix
        ret


; ------------------------------------------------------------
; unsigned char mycron_bldr(mycron_sector_io_t *p) __z88dk_fastcall;
;
; Raw 128-byte sector read.
; ------------------------------------------------------------

_mycron_bldr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BLDR
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; unsigned char mycron_budr(mycron_sector_io_t *p) __z88dk_fastcall;
;
; Raw 128-byte sector write.
; ------------------------------------------------------------

_mycron_budr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BUDR
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; unsigned char mycron_brdr(mycron_sector_io_t *p) __z88dk_fastcall;
;
; Standard-format buffer read.
;
; MYCROP BRDR expects HL to point to a standard text buffer.
; The monitor itself skips the 3-byte buffer header before
; doing the raw read.
; ------------------------------------------------------------

_mycron_brdr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BRDR
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; unsigned char mycron_bwdr(mycron_sector_io_t *p) __z88dk_fastcall;
; ------------------------------------------------------------

_mycron_bwdr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BWDR
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; unsigned char mycron_bddr(mycron_sector_io_t *p) __z88dk_fastcall;
; ------------------------------------------------------------

_mycron_bddr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BDDR
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; unsigned char mycron_load(mycron_load_params_t *p) __z88dk_fastcall;
;
; Struct layout:
;
;   +0 unit
;   +1 name8 pointer low
;   +2 name8 pointer high
;   +3 entry low
;   +4 entry high
;
; MYCROP LOAD:
;
;   A  = unit
;   BC = pointer to 8-byte, space-padded program name
;
; Return:
;
;   carry clear: success, HL = entry
;   carry set:   error, A = error code
;
; This wrapper:
;
;   returns 0 on success
;   returns MYCROP error code on failure
;   stores entry address into p->entry on success
; ------------------------------------------------------------

_mycron_load:
        push    ix
        push    hl
        pop     ix

        ld      a,(ix+0)
        ld      c,(ix+1)
        ld      b,(ix+2)

        call    MYCROP_LOAD

        jr      c,mycron_load_error

        ; success: store returned HL into p->entry
        ld      (ix+3),l
        ld      (ix+4),h

        xor     a

mycron_load_error:
        ld      l,a
        ld      h,0
        pop     ix
        ret


; ------------------------------------------------------------
; unsigned char mycron_link(mycron_load_params_t *p) __z88dk_fastcall;
;
; MYCROP LINK:
;
;   A  = unit
;   BC = pointer to 8-byte, space-padded program name
;
; LINK does not return on success.
; It returns only on error with carry set and A = error code.
; ------------------------------------------------------------

_mycron_link:
        push    ix
        push    hl
        pop     ix

        ld      a,(ix+0)
        ld      c,(ix+1)
        ld      b,(ix+2)

        call    MYCROP_LINK

        ; If LINK returned, it failed.
        ; Return A as status.
        ld      l,a
        ld      h,0

        pop     ix
        ret
```

---

# 4. `mycron_disk.c`

Create:

```c
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
```

---

# 5. Disk test program

```c
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
```

---

# 6. Program load example

```c
#include <stdio.h>
#include <mycron.h>
#include <mycron_disk.h>

int main(void)
{
    char name[8];
    mycron_load_params_t lp;
    unsigned char st;

    mycron_make_name8(name, "MSYSTEM");

    lp.unit = 0;
    lp.name8 = name;
    lp.entry = 0;

    st = mycron_load(&lp);

    if (st == 0) {
        printf("Loaded at %p\n", lp.entry);
    } else {
        printf("LOAD failed: %u\n", st);
    }

    mycron_exit_to_monitor();
    return 0;
}
```

To load and start:

```c
st = mycron_link(&lp);
```

If successful, `mycron_link()` does not return.

---

# 7. Small memory allocator

For now I recommend a **small custom allocator** instead of trying to replace z88dk’s `malloc()` immediately.

This gives you:

```c
mycron_malloc()
mycron_free()
mycron_calloc()
mycron_realloc()
mycron_heap_init()
mycron_heap_available()
```

It uses a simple first-fit free list and a default static heap.

Later, if desired, you can alias standard `malloc/free` onto this allocator.

---

# 8. `mycron_alloc.h`

Create:

```c
#ifndef MYCRON_ALLOC_H
#define MYCRON_ALLOC_H

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Initialize allocator with a caller-supplied memory range.
 *
 * start inclusive, end exclusive.
 *
 * If you never call mycron_heap_init(), a small built-in static heap
 * is used automatically.
 */
void mycron_heap_init(void *start, void *end);

void *mycron_malloc(unsigned int size);
void mycron_free(void *ptr);
void *mycron_calloc(unsigned int count, unsigned int size);
void *mycron_realloc(void *ptr, unsigned int new_size);

unsigned int mycron_heap_available(void);

#ifdef __cplusplus
}
#endif

#endif
```

---

# 9. `mycron_alloc.c`

Create:

```c
#include <mycron_alloc.h>

#ifndef NULL
#define NULL ((void *)0)
#endif

#ifndef MYCRON_HEAP_SIZE
#define MYCRON_HEAP_SIZE 2048
#endif

typedef struct mycron_block {
    unsigned int size;
    struct mycron_block *next;
} mycron_block_t;

#define MYCRON_BLOCK_HDR_SIZE ((unsigned int)sizeof(mycron_block_t))

static unsigned char mycron_default_heap[MYCRON_HEAP_SIZE];

static mycron_block_t *mycron_free_list = NULL;
static unsigned char mycron_heap_ready = 0;


static unsigned int mycron_align2(unsigned int n)
{
    return (n + 1u) & 0xfffeu;
}


static void mycron_heap_ensure(void)
{
    if (!mycron_heap_ready) {
        mycron_heap_init(
            mycron_default_heap,
            mycron_default_heap + MYCRON_HEAP_SIZE
        );
    }
}


void mycron_heap_init(void *start, void *end)
{
    unsigned int s;
    unsigned int e;
    unsigned int bytes;

    s = (unsigned int)start;
    e = (unsigned int)end;

    s = mycron_align2(s);
    e &= 0xfffeu;

    if (e <= s + MYCRON_BLOCK_HDR_SIZE) {
        mycron_free_list = NULL;
        mycron_heap_ready = 1;
        return;
    }

    bytes = e - s;

    mycron_free_list = (mycron_block_t *)s;
    mycron_free_list->size = bytes - MYCRON_BLOCK_HDR_SIZE;
    mycron_free_list->next = NULL;

    mycron_heap_ready = 1;
}


void *mycron_malloc(unsigned int size)
{
    mycron_block_t *prev;
    mycron_block_t *cur;
    mycron_block_t *newblk;
    unsigned int need;
    unsigned int remaining;

    if (size == 0) {
        return NULL;
    }

    mycron_heap_ensure();

    need = mycron_align2(size);

    prev = NULL;
    cur = mycron_free_list;

    while (cur != NULL) {
        if (cur->size >= need) {
            remaining = cur->size - need;

            /*
             * Split only if the leftover can hold a header plus
             * at least 2 bytes of payload.
             */
            if (remaining >= MYCRON_BLOCK_HDR_SIZE + 2u) {
                newblk = (mycron_block_t *)(
                    ((unsigned char *)cur) +
                    MYCRON_BLOCK_HDR_SIZE +
                    need
                );

                newblk->size = remaining - MYCRON_BLOCK_HDR_SIZE;
                newblk->next = cur->next;

                cur->size = need;

                if (prev == NULL) {
                    mycron_free_list = newblk;
                } else {
                    prev->next = newblk;
                }
            } else {
                /*
                 * Use the whole block.
                 */
                if (prev == NULL) {
                    mycron_free_list = cur->next;
                } else {
                    prev->next = cur->next;
                }
            }

            return ((unsigned char *)cur) + MYCRON_BLOCK_HDR_SIZE;
        }

        prev = cur;
        cur = cur->next;
    }

    return NULL;
}


static void mycron_try_coalesce(mycron_block_t *blk)
{
    unsigned char *blk_end;

    if (blk == NULL || blk->next == NULL) {
        return;
    }

    blk_end = ((unsigned char *)blk) + MYCRON_BLOCK_HDR_SIZE + blk->size;

    if (blk_end == (unsigned char *)blk->next) {
        blk->size += MYCRON_BLOCK_HDR_SIZE + blk->next->size;
        blk->next = blk->next->next;
    }
}


void mycron_free(void *ptr)
{
    mycron_block_t *blk;
    mycron_block_t *prev;
    mycron_block_t *cur;

    if (ptr == NULL) {
        return;
    }

    mycron_heap_ensure();

    blk = (mycron_block_t *)(
        ((unsigned char *)ptr) - MYCRON_BLOCK_HDR_SIZE
    );

    prev = NULL;
    cur = mycron_free_list;

    /*
     * Insert sorted by address.
     */
    while (cur != NULL && (unsigned int)cur < (unsigned int)blk) {
        prev = cur;
        cur = cur->next;
    }

    blk->next = cur;

    if (prev == NULL) {
        mycron_free_list = blk;
    } else {
        prev->next = blk;
    }

    /*
     * Coalesce with next and previous if adjacent.
     */
    mycron_try_coalesce(blk);

    if (prev != NULL) {
        mycron_try_coalesce(prev);
    }
}


void *mycron_calloc(unsigned int count, unsigned int size)
{
    unsigned int total;
    unsigned int i;
    unsigned char *p;

    if (count == 0 || size == 0) {
        return NULL;
    }

    total = count * size;

    /*
     * Basic overflow check for 16-bit unsigned int.
     */
    if (total / count != size) {
        return NULL;
    }

    p = (unsigned char *)mycron_malloc(total);

    if (p == NULL) {
        return NULL;
    }

    for (i = 0; i < total; ++i) {
        p[i] = 0;
    }

    return p;
}


void *mycron_realloc(void *ptr, unsigned int new_size)
{
    mycron_block_t *oldblk;
    void *newptr;
    unsigned int old_size;
    unsigned int copy_size;
    unsigned int i;
    unsigned char *src;
    unsigned char *dst;

    if (ptr == NULL) {
        return mycron_malloc(new_size);
    }

    if (new_size == 0) {
        mycron_free(ptr);
        return NULL;
    }

    oldblk = (mycron_block_t *)(
        ((unsigned char *)ptr) - MYCRON_BLOCK_HDR_SIZE
    );

    old_size = oldblk->size;

    if (new_size <= old_size) {
        return ptr;
    }

    newptr = mycron_malloc(new_size);
    if (newptr == NULL) {
        return NULL;
    }

    copy_size = old_size;
    if (copy_size > new_size) {
        copy_size = new_size;
    }

    src = (unsigned char *)ptr;
    dst = (unsigned char *)newptr;

    for (i = 0; i < copy_size; ++i) {
        dst[i] = src[i];
    }

    mycron_free(ptr);

    return newptr;
}


unsigned int mycron_heap_available(void)
{
    mycron_block_t *cur;
    unsigned int total;

    mycron_heap_ensure();

    total = 0;
    cur = mycron_free_list;

    while (cur != NULL) {
        total += cur->size;
        cur = cur->next;
    }

    return total;
}
```

---

# 10. Allocator test program

```c
#include <stdio.h>
#include <mycron.h>
#include <mycron_alloc.h>

int main(void)
{
    char *p;
    char *q;

    printf("Allocator test\n");
    printf("available initially: %u\n", mycron_heap_available());

    p = mycron_malloc(32);
    q = mycron_malloc(64);

    printf("p = %p\n", p);
    printf("q = %p\n", q);
    printf("available after alloc: %u\n", mycron_heap_available());

    if (p) {
        p[0] = 'O';
        p[1] = 'K';
        p[2] = 0;
        printf("p string = %s\n", p);
    }

    mycron_free(p);
    mycron_free(q);

    printf("available after free: %u\n", mycron_heap_available());

    mycron_exit_to_monitor();
    return 0;
}
```

---

# 11. Optional: use a larger heap

By default:

```c
#define MYCRON_HEAP_SIZE 2048
```

You can override this from the build/config with:

```text
-DMYCRON_HEAP_SIZE=8192
```

If you want this as a Mycron target default, add to your `OPTIONS` line in `mycron.cfg`:

```text
-DMYCRON_HEAP_SIZE=8192
```

---

# 12. Optional: initialize heap to a manual address range

If you know a memory range is safe, you can use it directly:

```c
mycron_heap_init((void *)0x9000, (void *)0xf000);
```

Then `mycron_malloc()` uses that arena instead of the static heap.

Do this only if you are sure it does not overlap:

- z88dk code
- z88dk initialized data/BSS
- your stack
- disk buffers
- MYCROP workspace

The static default heap is safer for initial testing.

---

# 13. Adding files to `mycron.cfg`

Since you found the correct solution — adding options to the existing `OPTIONS` line and support files to the `CLIB classic` line — add these.

## Include paths / defines

In the existing `OPTIONS` line, make sure you have something like:

```text
-I/work/z88dk-local/target/mycron/include
```

Optionally:

```text
-DMYCRON_HEAP_SIZE=4096
```

## Classic support files

In the `CLIB classic` line, add:

```text
/work/z88dk-local/target/mycron/classic/mycron_stdio.asm
/work/z88dk-local/target/mycron/classic/mycron_disk.asm
/work/z88dk-local/target/mycron/classic/mycron_disk.c
/work/z88dk-local/target/mycron/classic/mycron_alloc.c
```

If z88dk does not like `.c` files in the `CLIB classic` line, keep the `.asm` files there and add the `.c` support files explicitly in the build for now. But try it first; if your current `CLIB classic` accepts source paths, it may work.

---

# 14. Notes and caveats

## Disk routines are low-level

These wrappers do not implement a C filesystem. They expose MYCROP sector/program-loader services.

So this works:

```c
mycron_disk_read_sector(0, 0, 7, buffer);
```

But this does not exist yet:

```c
fopen("FILE.TXT", "r");
```

That can come later.

## `BUDR` writes raw sectors

Be careful with `mycron_disk_write_sector()`. It writes a full 128-byte sector.

Test reads first.

## `LOAD` expects an 8-byte name

Use:

```c
char name[8];
mycron_make_name8(name, "MSYSTEM");
```

Do not pass a normal NUL-terminated string directly to `mycron_load()`.

## The allocator is not interrupt-safe

That is fine for now because we are keeping interrupts disabled for C programs.

---

# Summary

Add:

```text
mycron_disk.h
mycron_alloc.h
mycron_disk.asm
mycron_disk.c
mycron_alloc.c
```

Then you get:

```c
mycron_disk_read_sector()
mycron_disk_write_sector()
mycron_load()
mycron_link()
mycron_malloc()
mycron_free()
mycron_calloc()
mycron_realloc()
```

This gives you a useful Mycron-specific runtime layer without trying to fake a complete hosted operating system yet.
