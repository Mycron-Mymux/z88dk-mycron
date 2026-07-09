Yes — that is probably the right direction.

Keep `+mycron` minimal by default:

- startup/origin/stack settings
- stdio hooks
- `mycron.h` include path

Then make optional libraries:

```text
mycron_disk.lib
mycron_alloc.lib
```

and link them only when needed:

```sh
zcc +mycron -Oz -m -create-app -o diskdemo diskdemo.c \
    -L/work/build/lib -lmycron_disk

zcc +mycron -Oz -m -create-app -o alloctest alloctest.c \
    -L/work/build/lib -lmycron_alloc
```

This avoids pulling disk or allocator code into every tiny hello-world program.

---

# 1. Important principle: library granularity

z88dk libraries are archives of object modules. The linker pulls in object modules that satisfy unresolved symbols.

So if you put all disk functions into one object file:

```text
mycron_disk.o
```

then using one disk function may pull in all disk wrappers.

If you split them:

```text
mycron_bdo.o
mycron_bdc.o
mycron_bldr.o
mycron_budr.o
mycron_load.o
mycron_disk_read_sector.o
...
```

then only the required modules are pulled in.

For the disk library, splitting is worth doing.

For the allocator, one object file is acceptable because the allocator functions share internal static state and tend to be used together.

---

# 2. Suggested directory layout

```text
mycron-z88dk/
├── z88dk-local/
│   └── target/
│       └── mycron/
│           ├── include/
│           │   ├── mycron.h
│           │   ├── mycron_disk.h
│           │   └── mycron_alloc.h
│           └── classic/
│               ├── mycron_stdio.asm
│               ├── disk/
│               │   ├── mycron_bdo.asm
│               │   ├── mycron_bdc.asm
│               │   ├── mycron_bdd.asm
│               │   ├── mycron_bldr.asm
│               │   ├── mycron_budr.asm
│               │   ├── mycron_brdr.asm
│               │   ├── mycron_bwdr.asm
│               │   ├── mycron_bddr.asm
│               │   ├── mycron_load.asm
│               │   ├── mycron_link.asm
│               │   ├── mycron_disk_read_sector.c
│               │   ├── mycron_disk_write_sector.c
│               │   └── mycron_make_name8.c
│               └── alloc/
│                   └── mycron_alloc.c
├── build/
│   ├── obj/
│   └── lib/
├── examples/
│   ├── hello.c
│   ├── diskdemo.c
│   └── alloctest.c
└── Makefile
```

---

# 3. Building z88dk libraries

The basic process is:

1. compile each `.asm` or `.c` file to `.o`
2. archive the `.o` files into a `.lib` using `z80asm -x`
3. link with `-L... -l...`

Example:

```sh
z80asm -xbuild/lib/mycron_disk.lib @build/mycron_disk_objects.lst
```

where `build/mycron_disk_objects.lst` contains one object path per line:

```text
build/obj/mycron_bdo.o
build/obj/mycron_bdc.o
build/obj/mycron_bldr.o
...
```

---

# 4. Split disk wrapper examples

Instead of one large `mycron_disk.asm`, split the simple monitor calls.

## `mycron_bdo.asm`

```asm
        MODULE  mycron_bdo

        SECTION code_clib

        defc    MYCROP_BDO = 0070h

        PUBLIC  _mycron_bdo

; unsigned char mycron_bdo(unsigned char unit) __z88dk_fastcall;
_mycron_bdo:
        ld      a,l
        call    MYCROP_BDO
        ld      l,a
        ld      h,0
        ret
```

## `mycron_bdc.asm`

```asm
        MODULE  mycron_bdc

        SECTION code_clib

        defc    MYCROP_BDC = 007Ch

        PUBLIC  _mycron_bdc

; unsigned char mycron_bdc(unsigned char unit) __z88dk_fastcall;
_mycron_bdc:
        ld      a,l
        call    MYCROP_BDC
        ld      l,a
        ld      h,0
        ret
```

## `mycron_bdd.asm`

```asm
        MODULE  mycron_bdd

        SECTION code_clib

        defc    MYCROP_BDD = 007Fh

        PUBLIC  _mycron_bdd

; unsigned char mycron_bdd(unsigned char unit) __z88dk_fastcall;
_mycron_bdd:
        ld      a,l
        call    MYCROP_BDD
        ld      l,a
        ld      h,0
        ret
```

---

# 5. Raw sector parameter setup

For the sector functions, you can either duplicate the parameter setup in each file or share one helper module.

For library friendliness, make a helper object:

## `mycron_disk_setup_sector_params.asm`

```asm
        MODULE  mycron_disk_setup_sector_params

        SECTION code_clib

        PUBLIC  mycron_disk_setup_sector_params

; Internal helper.
;
; Input:
;   HL = mycron_sector_io_t *
;
; Output:
;   A  = unit
;   B  = track
;   C  = sector
;   D  = bad74
;   E  = bad75
;   HL = buffer address
;
; Struct:
;   +0 unit
;   +1 track
;   +2 sector
;   +3 bad74
;   +4 bad75
;   +5 addr low
;   +6 addr high

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
```

## `mycron_bldr.asm`

```asm
        MODULE  mycron_bldr

        SECTION code_clib

        defc    MYCROP_BLDR = 0082h

        PUBLIC  _mycron_bldr
        EXTERN  mycron_disk_setup_sector_params

; unsigned char mycron_bldr(mycron_sector_io_t *p) __z88dk_fastcall;
_mycron_bldr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BLDR
        ld      l,a
        ld      h,0
        ret
```

## `mycron_budr.asm`

```asm
        MODULE  mycron_budr

        SECTION code_clib

        defc    MYCROP_BUDR = 0085h

        PUBLIC  _mycron_budr
        EXTERN  mycron_disk_setup_sector_params

; unsigned char mycron_budr(mycron_sector_io_t *p) __z88dk_fastcall;
_mycron_budr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BUDR
        ld      l,a
        ld      h,0
        ret
```

You can do the same for:

```text
mycron_brdr.asm  -> call 0073h
mycron_bwdr.asm  -> call 0076h
mycron_bddr.asm  -> call 0079h
```

---

# 6. `LOAD` and `LINK` wrappers

## `mycron_load.asm`

```asm
        MODULE  mycron_load

        SECTION code_clib

        defc    MYCROP_LOAD = 006Dh

        PUBLIC  _mycron_load

; unsigned char mycron_load(mycron_load_params_t *p) __z88dk_fastcall;
;
; Struct:
;   +0 unit
;   +1 name8 pointer low
;   +2 name8 pointer high
;   +3 entry low
;   +4 entry high
;
; Returns:
;   0 on success, p->entry set
;   error code on failure

_mycron_load:
        push    ix
        push    hl
        pop     ix

        ld      a,(ix+0)
        ld      c,(ix+1)
        ld      b,(ix+2)

        call    MYCROP_LOAD

        jr      c,mycron_load_error

        ld      (ix+3),l
        ld      (ix+4),h

        xor     a

mycron_load_error:
        ld      l,a
        ld      h,0
        pop     ix
        ret
```

## `mycron_link.asm`

```asm
        MODULE  mycron_link

        SECTION code_clib

        defc    MYCROP_LINK = 0088h

        PUBLIC  _mycron_link

; unsigned char mycron_link(mycron_load_params_t *p) __z88dk_fastcall;
;
; Does not return on success.
; Returns error code on failure.

_mycron_link:
        push    ix
        push    hl
        pop     ix

        ld      a,(ix+0)
        ld      c,(ix+1)
        ld      b,(ix+2)

        call    MYCROP_LINK

        ; If LINK returned, it failed.
        ld      l,a
        ld      h,0

        pop     ix
        ret
```

---

# 7. C convenience modules

Split these too, so the linker only pulls what is used.

## `mycron_make_name8.c`

```c
#include <mycron_disk.h>

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
```

## `mycron_disk_read_sector.c`

```c
#include <mycron_disk.h>

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

    mycron_bdc(unit);

    return st;
}
```

## `mycron_disk_write_sector.c`

```c
#include <mycron_disk.h>

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

    mycron_bdc(unit);

    return st;
}
```

---

# 8. Allocator library

For the allocator, keep it in one object initially:

```text
mycron_alloc.c -> mycron_alloc.o -> mycron_alloc.lib
```

That is fine because:

- `mycron_malloc`
- `mycron_free`
- `mycron_realloc`
- `mycron_calloc`

share static allocator state.

If you later want maximum size reduction, you can split it, but it is not necessary now.

---

# 9. Build commands manually

Inside Docker, from `/work`:

```sh
mkdir -p build/obj build/lib
```

Compile disk objects:

```sh
zcc +mycron -c -O2 \
    -I/work/z88dk-local/target/mycron/include \
    -o build/obj/mycron_bdo.o \
    z88dk-local/target/mycron/classic/disk/mycron_bdo.asm

zcc +mycron -c -O2 \
    -I/work/z88dk-local/target/mycron/include \
    -o build/obj/mycron_bdc.o \
    z88dk-local/target/mycron/classic/disk/mycron_bdc.asm

zcc +mycron -c -O2 \
    -I/work/z88dk-local/target/mycron/include \
    -o build/obj/mycron_disk_read_sector.o \
    z88dk-local/target/mycron/classic/disk/mycron_disk_read_sector.c
```

Repeat for the rest.

Then create an object list:

```sh
cat > build/mycron_disk_objects.lst <<EOF
build/obj/mycron_bdo.o
build/obj/mycron_bdc.o
build/obj/mycron_bdd.o
build/obj/mycron_disk_setup_sector_params.o
build/obj/mycron_bldr.o
build/obj/mycron_budr.o
build/obj/mycron_brdr.o
build/obj/mycron_bwdr.o
build/obj/mycron_bddr.o
build/obj/mycron_load.o
build/obj/mycron_link.o
build/obj/mycron_make_name8.o
build/obj/mycron_disk_read_sector.o
build/obj/mycron_disk_write_sector.o
EOF
```

Create the library:

```sh
z80asm -xbuild/lib/mycron_disk.lib @build/mycron_disk_objects.lst
```

Build allocator:

```sh
zcc +mycron -c -O2 \
    -I/work/z88dk-local/target/mycron/include \
    -o build/obj/mycron_alloc.o \
    z88dk-local/target/mycron/classic/alloc/mycron_alloc.c

cat > build/mycron_alloc_objects.lst <<EOF
build/obj/mycron_alloc.o
EOF

z80asm -xbuild/lib/mycron_alloc.lib @build/mycron_alloc_objects.lst
```

---

# 10. Linking with the libraries

Then compile programs like:

```sh
zcc +mycron -Oz -m -create-app \
    -I/work/z88dk-local/target/mycron/include \
    -L/work/build/lib \
    -o diskdemo \
    examples/diskdemo.c \
    -lmycron_disk
```

For allocator:

```sh
zcc +mycron -Oz -m -create-app \
    -I/work/z88dk-local/target/mycron/include \
    -L/work/build/lib \
    -o alloctest \
    examples/alloctest.c \
    -lmycron_alloc
```

For both:

```sh
zcc +mycron -Oz -m -create-app \
    -I/work/z88dk-local/target/mycron/include \
    -L/work/build/lib \
    -o demo \
    examples/demo.c \
    -lmycron_disk \
    -lmycron_alloc
```

Library order matters: put libraries **after** the C source/object files that reference them.

If `-L/-l` gives trouble, pass the library path directly:

```sh
zcc +mycron -Oz -m -create-app \
    -o diskdemo \
    examples/diskdemo.c \
    /work/build/lib/mycron_disk.lib
```

---

# 11. Docker Makefile example

```make
IMAGE = z88dk/z88dk
ZCCCFG_IN_CONTAINER = /opt/z88dk/lib/config

DOCKER = docker run --rm \
	-v $(CURDIR):/work \
	-v $(CURDIR)/z88dk-local/config/mycron.cfg:$(ZCCCFG_IN_CONTAINER)/mycron.cfg:ro \
	-w /work \
	$(IMAGE)

ZCC = $(DOCKER) zcc
Z80ASM = $(DOCKER) z80asm

INC = -I/work/z88dk-local/target/mycron/include

OBJDIR = build/obj
LIBDIR = build/lib

DISK_OBJS = \
	$(OBJDIR)/mycron_bdo.o \
	$(OBJDIR)/mycron_bdc.o \
	$(OBJDIR)/mycron_bdd.o \
	$(OBJDIR)/mycron_disk_setup_sector_params.o \
	$(OBJDIR)/mycron_bldr.o \
	$(OBJDIR)/mycron_budr.o \
	$(OBJDIR)/mycron_brdr.o \
	$(OBJDIR)/mycron_bwdr.o \
	$(OBJDIR)/mycron_bddr.o \
	$(OBJDIR)/mycron_load.o \
	$(OBJDIR)/mycron_link.o \
	$(OBJDIR)/mycron_make_name8.o \
	$(OBJDIR)/mycron_disk_read_sector.o \
	$(OBJDIR)/mycron_disk_write_sector.o

ALLOC_OBJS = \
	$(OBJDIR)/mycron_alloc.o

all: $(LIBDIR)/mycron_disk.lib $(LIBDIR)/mycron_alloc.lib

$(OBJDIR) $(LIBDIR):
	mkdir -p $@

$(OBJDIR)/%.o: z88dk-local/target/mycron/classic/disk/%.asm | $(OBJDIR)
	$(ZCC) +mycron -c -O2 $(INC) -o /work/$@ /work/$<

$(OBJDIR)/%.o: z88dk-local/target/mycron/classic/disk/%.c | $(OBJDIR)
	$(ZCC) +mycron -c -O2 $(INC) -o /work/$@ /work/$<

$(OBJDIR)/%.o: z88dk-local/target/mycron/classic/alloc/%.c | $(OBJDIR)
	$(ZCC) +mycron -c -O2 $(INC) -o /work/$@ /work/$<

$(LIBDIR)/mycron_disk.lib: $(DISK_OBJS) | $(LIBDIR)
	printf '%s\n' $(addprefix /work/,$(DISK_OBJS)) > build/mycron_disk_objects.lst
	$(Z80ASM) -x/work/$@ @/work/build/mycron_disk_objects.lst

$(LIBDIR)/mycron_alloc.lib: $(ALLOC_OBJS) | $(LIBDIR)
	printf '%s\n' $(addprefix /work/,$(ALLOC_OBJS)) > build/mycron_alloc_objects.lst
	$(Z80ASM) -x/work/$@ @/work/build/mycron_alloc_objects.lst

diskdemo.bin: examples/diskdemo.c $(LIBDIR)/mycron_disk.lib
	$(ZCC) +mycron -Oz -m -create-app $(INC) -L/work/$(LIBDIR) \
		-o diskdemo /work/examples/diskdemo.c -lmycron_disk

alloctest.bin: examples/alloctest.c $(LIBDIR)/mycron_alloc.lib
	$(ZCC) +mycron -Oz -m -create-app $(INC) -L/work/$(LIBDIR) \
		-o alloctest /work/examples/alloctest.c -lmycron_alloc

clean:
	rm -rf build
	rm -f *.o *.bin *.map *.lis *.sym diskdemo alloctest zcc_opt.def
```

You may need to adjust `/opt/z88dk/lib/config` if your Docker image uses a different `ZCCCFG`.

---

# 12. Update `mycron.cfg`

Remove disk/allocator source files from the default `CLIB classic` line.

Keep only things needed by all Mycron programs, e.g.:

```text
CLIB classic ... /work/z88dk-local/target/mycron/classic/mycron_stdio.asm
```

Keep the include path in `OPTIONS`:

```text
-I/work/z88dk-local/target/mycron/include
```

Optionally add the library search path too:

```text
-L/work/build/lib
```

Then users can do:

```sh
zcc +mycron -Oz -m -create-app -o diskdemo diskdemo.c -lmycron_disk
```

instead of:

```sh
zcc +mycron -Oz -m -create-app -L/work/build/lib -o diskdemo diskdemo.c -lmycron_disk
```

But I would initially leave `-L/work/build/lib` explicit until the library build is stable.

---

# 13. Optional: standard `malloc` names

Initially, I recommend exposing only:

```c
mycron_malloc()
mycron_free()
mycron_calloc()
mycron_realloc()
```

Do not replace standard `malloc()` yet.

Later, if you want standard names, add a separate optional compatibility module, maybe:

```text
mycron_alloc_std.c
```

```c
#include <mycron_alloc.h>

void *malloc(unsigned int size)
{
    return mycron_malloc(size);
}

void free(void *ptr)
{
    mycron_free(ptr);
}

void *calloc(unsigned int count, unsigned int size)
{
    return mycron_calloc(count, size);
}

void *realloc(void *ptr, unsigned int size)
{
    return mycron_realloc(ptr, size);
}
```

Then place that in a separate library:

```text
mycron_alloc_std.lib
```

Use it only when you intentionally want to satisfy standard `malloc/free`.

---

# Summary

Yes, make them separate z88dk libraries.

The workflow is:

```sh
zcc +mycron -c file.asm -o file.o
zcc +mycron -c file.c   -o file.o
z80asm -xbuild/lib/mycron_disk.lib @object-list.txt
```

Then link manually:

```sh
zcc +mycron -Oz -m -create-app -o diskdemo diskdemo.c \
    -L/work/build/lib -lmycron_disk
```

Recommended:

- keep stdio in the default `+mycron` target
- make `mycron_disk.lib` optional
- make `mycron_alloc.lib` optional
- split disk modules for better unused-code elimination
- keep allocator as one object for now


