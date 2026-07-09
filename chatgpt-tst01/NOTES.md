@ 2026-07-09 torsdag 00:38 
---------------------------
Prompt to chat.uit.no with GPT 5.5 thinking

This is an updated version of the PROM files for the z80 Mycron computer. I want to use the C compiler from z88dk to create programs for the Mycron computer. Can you provide the necessary files (like source for the crt0 library) that I need to do this with a small hello world example? I need functionality for printing and reading keyboard input, but other functions (like disk I/O) can be added later. 
=========

Below is a **minimal freestanding z88dk setup** for building small C programs for the Z80 Mycron/MYCROP monitor.

This does **not** try to implement a full z88dk target or disk I/O yet. It gives you:

- a tiny `crt0`
- C-callable console output
- C-callable keyboard input
- a small hello/input example
- a build command/Makefile

It uses the MYCROP monitor entry points from your PROM:

```asm
0040h  MON    ; enter monitor
0046h  poll_read_con
0049h  CRLF
004Ch  TTCON  ; print NUL-terminated string, BC = pointer
0052h  TTI    ; blocking input, no echo, returns A
0055h  TTIO   ; blocking input, echo, returns A
0058h  TTO    ; output char, A = character
```

The example assumes programs are loaded at `0800h` and started with:

```text
*G0800
```

---

# Directory layout

Create something like this:

```text
mycron-z88dk/
├── Makefile
├── crt0_mycron.asm
├── mycron_io.asm
├── mycron.h
└── hello.c
```

---

# `crt0_mycron.asm`

This is the minimal C runtime entry point.

It:

1. starts at `0800h`
2. sets the stack
3. calls C `main()`
4. returns to the MYCROP monitor when `main()` returns

```asm
; crt0_mycron.asm
;
; Minimal crt0 for Mycron/MYCROP using z88dk.
;
; Program load/start address: 0800h
; Suggested monitor command:  G0800
;
; RAM note:
;   Old documentation says user RAM is roughly 0800h..0BE3h,
;   with monitor/breakpoint/interrupt workspace above that.
;   Therefore this uses 0BE4h as the initial stack.
;
; If your machine really has free RAM up to 0FCFh, you can move
; MYCRON_STACK upward, but do not overwrite 0FD0h..0FFFh since
; MYCROP uses that area.

        MODULE  crt0_mycron

        defc    MYCRON_ORG      = 0800h
        defc    MYCRON_STACK    = 0BE4h

        defc    MYCROP_MON      = 0040h

        PUBLIC  __Start
        PUBLIC  start

        EXTERN  _main

        org     MYCRON_ORG

__Start:
start:
        ; Optional: leave interrupts as monitor configured them.
        ; If your application does not handle interrupts, you may want:
        ; di

        ld      sp,MYCRON_STACK

        call    _main

        ; Return to MYCROP monitor.
        jp      MYCROP_MON
```

---

# `mycron_io.asm`

This exposes small C-callable functions.

The functions use z88dk fastcall convention where a single argument is passed in `HL`.

```asm
; mycron_io.asm
;
; Small C-callable wrappers around MYCROP console routines.
;
; C prototypes are in mycron.h.

        MODULE  mycron_io

        defc    MYCROP_MON      = 0040h
        defc    MYCROP_POLL     = 0046h
        defc    MYCROP_CRLF     = 0049h
        defc    MYCROP_TTCON    = 004Ch
        defc    MYCROP_TTCLF    = 004Fh
        defc    MYCROP_TTI      = 0052h
        defc    MYCROP_TTIO     = 0055h
        defc    MYCROP_TTO      = 0058h

        PUBLIC  _mycron_putchar
        PUBLIC  _mycron_puts
        PUBLIC  _mycron_puts_crlf
        PUBLIC  _mycron_crlf
        PUBLIC  _mycron_getchar
        PUBLIC  _mycron_getchar_echo
        PUBLIC  _mycron_pollchar
        PUBLIC  _mycron_exit_to_monitor


; ------------------------------------------------------------
; void mycron_putchar(unsigned char ch) __z88dk_fastcall;
;
; Entry:
;   L = character
; ------------------------------------------------------------
_mycron_putchar:
        ld      a,l
        call    MYCROP_TTO
        ret


; ------------------------------------------------------------
; void mycron_puts(const char *s) __z88dk_fastcall;
;
; Entry:
;   HL = pointer to NUL-terminated string
;
; MYCROP TTCON expects:
;   BC = pointer
; ------------------------------------------------------------
_mycron_puts:
        ld      b,h
        ld      c,l
        call    MYCROP_TTCON
        ret


; ------------------------------------------------------------
; void mycron_puts_crlf(const char *s) __z88dk_fastcall;
;
; Entry:
;   HL = pointer to NUL-terminated string
;
; MYCROP TTCLF prints string and then CR/LF.
; ------------------------------------------------------------
_mycron_puts_crlf:
        ld      b,h
        ld      c,l
        call    MYCROP_TTCLF
        ret


; ------------------------------------------------------------
; void mycron_crlf(void);
; ------------------------------------------------------------
_mycron_crlf:
        call    MYCROP_CRLF
        ret


; ------------------------------------------------------------
; int mycron_getchar(void);
;
; Blocking input, no echo.
;
; Return:
;   HL = character, 0..127
; ------------------------------------------------------------
_mycron_getchar:
        call    MYCROP_TTI
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; int mycron_getchar_echo(void);
;
; Blocking input, with echo.
;
; Return:
;   HL = character, 0..127
; ------------------------------------------------------------
_mycron_getchar_echo:
        call    MYCROP_TTIO
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; int mycron_pollchar(void);
;
; Nonblocking input.
;
; Return:
;   HL = character 0..127 if available
;   HL = -1 if no character available
;
; MYCROP poll_read_con:
;   Z set    = no char
;   NZ set   = char in A
; ------------------------------------------------------------
_mycron_pollchar:
        call    MYCROP_POLL
        jr      z,.no_char

        ld      l,a
        ld      h,0
        ret

.no_char:
        ld      hl,0FFFFh
        ret


; ------------------------------------------------------------
; void mycron_exit_to_monitor(void);
;
; Does not return unless user uses monitor return facilities.
; ------------------------------------------------------------
_mycron_exit_to_monitor:
        jp      MYCROP_MON
```

---

# `mycron.h`

```c
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

#ifdef __cplusplus
}
#endif

#endif
```

---

# `hello.c`

This is a small test program.

```c
#include "mycron.h"

int main(void)
{
    int ch;

    mycron_puts_crlf("Hello from z88dk on Mycron!");
    mycron_puts_crlf("Press a key:");

    ch = mycron_getchar_echo();

    mycron_crlf();
    mycron_puts("You pressed: ");
    mycron_putchar((unsigned char)ch);
    mycron_crlf();

    mycron_puts_crlf("Returning to MYCROP monitor.");

    return 0;
}
```

---

# `Makefile`

This uses z88dk in a freestanding way.

```make
ZCC      = zcc
TARGET   = +z80
COMPILER = -compiler=sccz80

CFLAGS   = $(TARGET) $(COMPILER) -O3 -vn -nostdlib
OBJS     = crt0_mycron.asm mycron_io.asm hello.c

all: hello.bin

hello.bin: $(OBJS)
	$(ZCC) $(CFLAGS) -m -create-app -o hello $(OBJS)

clean:
	rm -f *.o *.bin *.map *.lis *.sym hello hello_* zcc_opt.def
```

Build with:

```sh
make
```

Depending on your z88dk version, the raw binary may appear as one of:

```text
hello.bin
hello_CODE.bin
hello
```

If z88dk emits `hello_CODE.bin`, that is usually the file you want to load at `0800h`.

---

# Manual build command

If you do not want to use the Makefile:

```sh
zcc +z80 -compiler=sccz80 -O3 -vn -nostdlib -m -create-app \
    -o hello \
    crt0_mycron.asm mycron_io.asm hello.c
```

---

# Running it on MYCROP

Load the generated binary at address `0800h`.

Then from MYCROP:

```text
*G0800
```

Expected output:

```text
Hello from z88dk on Mycron!
Press a key:
```

After pressing a key, it echoes the key and returns to the monitor.

---

# Important memory notes

Your PROM comments mention the old documented layout:

```text
0000h-07FFh  PROM / monitor
0800h-0BFFh  RAM
0BE4h-0BFFh  monitor/breakpoint/interrupt usage
```

But your newer disassembly also shows MYCROP workspace around:

```text
0FD0h-0FFFh
```

So for the safest small setup:

```asm
program origin = 0800h
stack top      = 0BE4h
```

That gives only about 996 bytes between `0800h` and `0BE3h`, minus program size and stack usage.

For larger C programs you will probably want one of these:

1. confirm that RAM actually extends beyond `0BFFh`,
2. move user program code somewhere else,
3. reserve monitor workspace explicitly,
4. eventually create a proper linker memory map.

For now, this is enough for a small hello/input test.

---

# If your binary is padded with 0800h zero bytes

Some toolchains produce a binary image starting at address zero, with zero padding up to `0800h`.

If that happens, strip the first `0x800` bytes:

```sh
dd if=hello.bin of=hello_0800.bin bs=1 skip=$((0x800))
```

Then load `hello_0800.bin` at `0800h`.

Ideally, the final file should begin with the code from `crt0_mycron.asm`, not 2048 bytes of zeros.

---

# Adding a tiny line input helper

You can add this later in C if desired:

```c
#include "mycron.h"

char *mycron_getline(char *buf, unsigned int max)
{
    unsigned int i = 0;
    int ch;

    if (max == 0) {
        return buf;
    }

    while (i + 1 < max) {
        ch = mycron_getchar_echo();

        if (ch == '\r' || ch == '\n') {
            break;
        }

        if (ch == 0x7f || ch == 0x08) {
            if (i != 0) {
                --i;
                mycron_putchar('\b');
                mycron_putchar(' ');
                mycron_putchar('\b');
            }
            continue;
        }

        buf[i++] = (char)ch;
    }

    buf[i] = 0;
    mycron_crlf();

    return buf;
}
```

But for the first test, keep the program small.

---

# Later: mapping z88dk stdio

The above deliberately avoids `printf()` and `getchar()` from z88dk libc.

Later, you can make a real z88dk target by adding console hooks roughly equivalent to:

```text
fputc_cons  -> MYCROP TTO
fgetc_cons  -> MYCROP TTI or TTIO
getk        -> MYCROP poll_read_con
```

Then normal C code like this could work:

```c
#include <stdio.h>

int main(void)
{
    printf("Hello\n");
    return 0;
}
```

But for initial bring-up, the freestanding wrapper approach is much easier and avoids needing a full z88dk target configuration.



@ 2026-07-09 torsdag 00:44 
---------------------------
https://hub.docker.com/r/z88dk/z88dk
docker pull z88dk/z88dk

