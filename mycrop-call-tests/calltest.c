#include <stdio.h>
#include <mycron.h>
#include "m_calls.h"

#define START 230
#define N 50

int main(void)
{
    
    unsigned int res;
    printf("Trying u8 to bcd\n"); 

    for (int i = START;  i < START + N; i++) {
        res = mycron_u8_to_bcd(i);
        printf("Res for %2d was D: %3u H: %3x\n", i, res, res);
    }
    mycron_exit_to_monitor();
    return 0; 
}
