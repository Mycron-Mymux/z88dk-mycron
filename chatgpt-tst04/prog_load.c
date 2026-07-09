#include <stdio.h>
#include <mycron.h>
#include <mycron_disk.h>

int main(void)
{
    char name[8];
    mycron_load_params_t lp;
    unsigned char st;

    // mycron_make_name8(name, "MSYSTEM");
    mycron_make_name8(name, "CATALOG");

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

