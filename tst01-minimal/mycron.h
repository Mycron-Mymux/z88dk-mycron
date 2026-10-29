#ifndef MYCRON_H
#define MYCRON_H

/*
 * Minimal C interface to MYCROP monitor console.
 *
 * These are intentionally tiny and avoid z88dk stdio for now.
 */

#ifdef __cplusplus
extern "C" {
#endif

void mycron_putchar(unsigned char ch) __z88dk_fastcall;
void mycron_puts(const char *s) __z88dk_fastcall;
void mycron_puts_crlf(const char *s) __z88dk_fastcall;
void mycron_crlf(void);

int mycron_getchar(void);
int mycron_getchar_echo(void);
int mycron_pollchar(void);

void mycron_exit_to_monitor(void);

void mycron_di(void);
void mycron_ei(void);    

#ifdef __cplusplus
}
#endif

#endif


