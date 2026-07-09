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

