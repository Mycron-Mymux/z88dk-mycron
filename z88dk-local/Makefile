# Makefile to build the mycron target libaries
# Note that the libaries must be compiled with +z80, not +mycron to avoid duplicates of stdio functions.
IMAGE = z88dk/z88dk
ZCCCFG_IN_CONTAINER = /opt/z88dk/lib/config
ZLOCAL= $(CURDIR)

DOCKER = docker run --rm \
	-v $(CURDIR):/work \
	-v $(ZLOCAL):/z88dk-local/ \
	-v $(ZLOCAL)/config/mycron.cfg:$(ZCCCFG_IN_CONTAINER)/mycron.cfg:ro \
	-w /work \
	$(IMAGE)

ZCC = $(DOCKER) zcc
Z80ASM = $(DOCKER) z80asm

INC = -I/work/z88dk-local/target/mycron/include -I/z88dk-local/target/mycron/include/
CFLAGS= -clib=classic -compiler=sccz80 $(INC)

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

$(OBJDIR)/%.o: target/mycron/classic/disk/%.asm | $(OBJDIR)
	$(ZCC) +z80 -c -O2 $(CFLAGS) -o /work/$@ /work/$<

$(OBJDIR)/%.o: target/mycron/classic/disk/%.c | $(OBJDIR)
	$(ZCC) +z80 -c -O2 $(CFLAGS) -o /work/$@ /work/$<

$(OBJDIR)/%.o: target/mycron/classic/alloc/%.c | $(OBJDIR)
	$(ZCC) +z80 -c -O2 $(CFLAGS) -o /work/$@ /work/$<

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
	rm -f build/lib/* build/obj/* 
