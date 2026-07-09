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

