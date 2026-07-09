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

