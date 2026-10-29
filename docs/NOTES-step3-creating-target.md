@ 2026-07-09 torsdag 02:52
---------------------------

That works, but I think we should take the next step and create a +mycron target to make it easier to write programs. How do I set up this target? Do I need to modify anything in the compiler setup, or is it a local change? 
====
Yes — the next step is a good idea.

You do **not** need to modify or rebuild the compiler. z88dk targets are mostly configuration files plus target support assembly/library files.

You have two choices:

1. **Install-level target**: add `mycron.cfg` and support files to your z88dk installation.
2. **Project-local target overlay**: copy/overlay z88dk’s config directory locally and set `ZCCCFG`.

I recommend starting with the **project-local overlay**, because it is reversible and does not affect your system z88dk install.

---

# Goal

Eventually you want to compile with something like:

```sh
zcc +mycron -O3 -m -create-app -o hello hello.c
```

instead of:

```sh
zcc +z80 -clib=classic -compiler=sccz80 -O3 -vn \
    -zorg=0x3000 \
    -pragma-define:REGISTER_SP=0xfff0 \
    -pragma-define:CRT_ENABLE_EIDI=0 \
    -pragma-redirect:fputc_cons=mycron_fputc_cons \
    -pragma-redirect:fgetc_cons=mycron_fgetc_cons \
    -pragma-redirect:getk=mycron_getk \
    -pragma-redirect:getkey=mycron_getkey \
    -m -create-app \
    -o hello \
    mycron_stdio.asm hello.c
```

---

# Recommended directory layout

Inside your project:

```text
mycron-z88dk/
├── z88dk-local/
│   ├── config/
│   │   ├── mycron.cfg
│   │   └── ... copied/symlinked z88dk config files ...
│   └── target/
│       └── mycron/
│           ├── classic/
│           │   └── mycron_stdio.asm
│           └── include/
│               └── mycron.h
├── examples/
│   └── hello.c
└── Makefile
```

---

# Step 1: find your z88dk config directory

Usually z88dk uses the environment variable:

```sh
echo "$ZCCCFG"
```

You may see something like:

```text
/usr/local/share/z88dk/lib/config
```

or:

```text
/opt/z88dk/lib/config
```

If `ZCCCFG` is empty, try:

```sh
zcc +z80 -vn
```

or check your z88dk installation path.

---

# Step 2: create a local config overlay

From your project directory:

```sh
mkdir -p z88dk-local/config
mkdir -p z88dk-local/target/mycron/classic
mkdir -p z88dk-local/target/mycron/include
```

Copy the existing z88dk config files locally:

```sh
cp -a "$ZCCCFG"/* z88dk-local/config/
```

Then copy the generic Z80 config as a starting point:

```sh
cp z88dk-local/config/z80.cfg z88dk-local/config/mycron.cfg
```

This is the safest method because z88dk `.cfg` files are version-dependent. Starting from your known-working `z80.cfg` avoids having to recreate all the internal z88dk config logic.

---

# Step 3: add Mycron stdio support file

Create:

```text
z88dk-local/target/mycron/classic/mycron_stdio.asm
```

Use the renamed-function version that already worked:

```asm
; mycron_stdio.asm
;
; Mycron/MYCROP console routines for z88dk classic stdio.
;
; These are deliberately not named fputc_cons/fgetc_cons directly,
; because the generic +z80 classic CRT already defines those names.
;
; mycron.cfg redirects:
;
;   fputc_cons -> mycron_fputc_cons
;   fgetc_cons -> mycron_fgetc_cons
;   getk       -> mycron_getk
;   getkey     -> mycron_getkey

        MODULE  mycron_stdio

        SECTION code_clib

        defc    MYCROP_MON      = 0040h
        defc    MYCROP_POLL     = 0046h
        defc    MYCROP_TTI      = 0052h
        defc    MYCROP_TTO      = 0058h

        PUBLIC  mycron_fputc_cons
        PUBLIC  mycron_fgetc_cons
        PUBLIC  mycron_getk
        PUBLIC  mycron_getkey

        PUBLIC  _mycron_exit_to_monitor


; ------------------------------------------------------------
; Replacement for classic fputc_cons.
;
; Character argument is on stack at SP+2.
; Converts '\n' to CR/LF.
; ------------------------------------------------------------

mycron_fputc_cons:
        ld      hl,2
        add     hl,sp
        ld      a,(hl)

        cp      10              ; '\n'
        jr      nz,mycron_fputc_not_lf

        ld      a,13            ; '\r'
        call    MYCROP_TTO
        ld      a,10            ; '\n'
        call    MYCROP_TTO
        ret

mycron_fputc_not_lf:
        call    MYCROP_TTO
        ret


; ------------------------------------------------------------
; Replacement for classic fgetc_cons.
;
; Blocking read.
; Echoes input manually.
; Converts CR to '\n'.
; ------------------------------------------------------------

mycron_fgetc_cons:
        call    MYCROP_TTI      ; blocking input, no echo

        cp      13              ; CR?
        jr      nz,mycron_fgetc_not_cr

        ld      a,13
        call    MYCROP_TTO
        ld      a,10
        call    MYCROP_TTO

        ld      hl,10           ; return '\n'
        ret

mycron_fgetc_not_cr:
        push    af
        call    MYCROP_TTO      ; echo character
        pop     af

        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; Replacement for classic getk.
;
; Nonblocking key poll.
;
; Return:
;   HL = 0 if no key
;   HL = character otherwise
; ------------------------------------------------------------

mycron_getk:
        call    MYCROP_POLL
        jr      z,mycron_getk_no_key

        cp      13
        jr      nz,mycron_getk_not_cr
        ld      a,10

mycron_getk_not_cr:
        ld      l,a
        ld      h,0
        ret

mycron_getk_no_key:
        ld      hl,0
        ret


; ------------------------------------------------------------
; Replacement for classic getkey.
;
; Blocking, no echo.
; Converts CR to '\n'.
; ------------------------------------------------------------

mycron_getkey:
        call    MYCROP_TTI

        cp      13
        jr      nz,mycron_getkey_not_cr
        ld      a,10

mycron_getkey_not_cr:
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; void mycron_exit_to_monitor(void);
; ------------------------------------------------------------

_mycron_exit_to_monitor:
        jp      MYCROP_MON
```

---

# Step 4: add a small Mycron header

Create:

```text
z88dk-local/target/mycron/include/mycron.h
```

```c
#ifndef MYCRON_H
#define MYCRON_H

#ifdef __cplusplus
extern "C" {
#endif

void mycron_exit_to_monitor(void);

#ifdef __cplusplus
}
#endif

#endif
```

Later you can add disk routines, monitor calls, direct console calls, etc.

---

# Step 5: edit `mycron.cfg`

Open:

```text
z88dk-local/config/mycron.cfg
```

Since this was copied from `z80.cfg`, most of the hard work is already done.

At the **end** of `mycron.cfg`, add Mycron-specific defaults.

Use an **absolute path** for the support assembly file at first. This avoids ambiguity about how your z88dk version resolves paths inside config files.

For example:

```text
# ----------------------------------------------------------------------
# Mycron / MYCROP target additions
# ----------------------------------------------------------------------

-clib=classic
-compiler=sccz80

-zorg=0x3000

-pragma-define:REGISTER_SP=0xfff0
-pragma-define:CRT_ENABLE_EIDI=0

-pragma-redirect:fputc_cons=mycron_fputc_cons
-pragma-redirect:fgetc_cons=mycron_fgetc_cons
-pragma-redirect:getk=mycron_getk
-pragma-redirect:getkey=mycron_getkey

-I/full/path/to/mycron-z88dk/z88dk-local/target/mycron/include

/full/path/to/mycron-z88dk/z88dk-local/target/mycron/classic/mycron_stdio.asm
```

Replace:

```text
/full/path/to/mycron-z88dk
```

with the real path.

For example:

```text
/home/you/src/mycron-z88dk/z88dk-local/target/mycron/classic/mycron_stdio.asm
```

Yes, the absolute path is ugly, but it is reliable for the first version.

Once it works, you can clean it up.

---

# Step 6: tell z88dk to use the local config directory

In your shell:

```sh
export ZCCCFG="$PWD/z88dk-local/config"
```

Now z88dk should find:

```text
z88dk-local/config/mycron.cfg
```

when you use:

```sh
+mycron
```

You can check with:

```sh
zcc +mycron -vn
```

---

# Step 7: test program

Create:

```text
examples/hello.c
```

```c
#include <stdio.h>
#include <mycron.h>

int main(void)
{
    int c;

    printf("Hello from +mycron!\n");
    printf("Press a key: ");

    c = getchar();

    printf("\nYou pressed '%c' = %d = 0x%02x\n", c, c, c);
    printf("Returning to MYCROP monitor.\n");

    mycron_exit_to_monitor();

    return 0;
}
```

---

# Step 8: build with the new target

```sh
zcc +mycron -O3 -vn -m -create-app \
    -o hello \
    examples/hello.c
```

If you added `-compiler=sccz80`, `-clib=classic`, `-zorg`, stack, redirects, and support asm inside `mycron.cfg`, you should no longer need to provide those on the command line.

---

# Step 9: verify the binary

Check the first few bytes:

```sh
xxd -g1 -l32 hello.bin
```

You want to see:

```text
f3 31 f0 ff ...
```

That is:

```asm
di
ld sp,0fff0h
```

Also verify there is no `ei` before `main`.

Check symbols:

```sh
grep -E "main|mycron|fputc|getk|getkey|REGISTER|Start" hello.map
```

You should see program symbols around `3000h`, for example:

```text
_main                  = $31xx
mycron_fputc_cons      = $30xx
mycron_fgetc_cons      = $30xx
_mycron_exit_to_monitor = $30xx
```

---

# Step 10: run on the machine

Load the generated binary at:

```text
3000h
```

Then start from MYCROP:

```text
*G3000
```

---

# Example Makefile using `+mycron`

```make
ZCC = zcc

# Use local z88dk config overlay.
export ZCCCFG := $(CURDIR)/z88dk-local/config

CFLAGS = +mycron -O3 -vn -m -create-app

all: hello.bin

hello.bin: examples/hello.c
	$(ZCC) $(CFLAGS) -o hello examples/hello.c

clean:
	rm -f *.o *.bin *.map *.lis *.sym hello hello_* zcc_opt.def
```

Build:

```sh
make clean
make
```

---

# Do you need to modify the compiler?

No.

You do **not** need to rebuild:

```text
zcc
sccz80
z80asm
appmake
```

A z88dk target is mostly:

```text
configuration
crt0/startup
console hooks
optional libraries
optional appmake support
```

So this is a local/toolchain-data change, not a compiler-source change.

---

# Install-level version

Once the local target works, you can install it into your real z88dk tree.

If your real config directory is:

```text
/usr/local/share/z88dk/lib/config
```

then you would install:

```text
/usr/local/share/z88dk/lib/config/mycron.cfg
/usr/local/share/z88dk/lib/target/mycron/classic/mycron_stdio.asm
/usr/local/share/z88dk/lib/target/mycron/include/mycron.h
```

Then change the paths in `mycron.cfg` from local absolute paths to installed absolute paths, or paths matching z88dk’s existing target conventions.

Then you can use:

```sh
zcc +mycron -O3 -m -create-app -o hello hello.c
```

from any directory.

---

# Important note about `return 0`

At this stage, I would still write programs like this:

```c
mycron_exit_to_monitor();
```

rather than relying on:

```c
return 0;
```

Because this first `+mycron` target is still based on the generic `+z80` CRT. It sets the stack and stdio correctly, but its post-`main()` behavior may not be ideal for MYCROP.

A later, more polished target should include a Mycron-specific `crt0` that does:

```asm
call _main
jp 0040h      ; MYCROP monitor
```

after `main()` returns.

That is the next cleanup step.

---

# Recommended development stages

## Stage 1: local `+mycron` config

What we are doing now.

Provides:

```c
printf()
puts()
putchar()
getchar()
strlen()
memcpy()
sprintf()
```

and so on.

Still uses generic z80 CRT.

## Stage 2: Mycron-specific CRT

Make `return 0;` automatically return to MYCROP.

Also remove the need for some generic z80 CRT behavior you do not want.

## Stage 3: Mycron runtime library

Move `mycron_stdio.asm` into a proper `.lib`, so the config links it as a library instead of injecting an asm source file.

## Stage 4: disk API

Add wrappers for:

```asm
BDO   0070h
BRDR  0073h
BWDR  0076h
BDC   007Ch
BLDR  0082h
BUDR  0085h
LOAD  006Dh
LINK  0088h
```

Initially expose them as Mycron-specific C functions, not full `fopen()`.

---

# Bottom line

You can make this a local target. You do not need to rebuild z88dk.

The easiest safe path is:

1. copy `z80.cfg` to `mycron.cfg`
2. append the Mycron options that already work
3. add `mycron_stdio.asm`
4. set `ZCCCFG` to your local config directory
5. build with `zcc +mycron`

Once stable, you can install those files into the z88dk tree or keep the local overlay in your project.



