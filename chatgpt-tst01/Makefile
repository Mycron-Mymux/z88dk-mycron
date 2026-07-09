IMAGE = z88dk/z88dk

ZLOCAL = $(CURDIR)/../z88dk-local/

# Adjust if your z88dk container reports a different ZCCCFG.
ZCCCFG_IN_CONTAINER = /opt/z88dk/lib/config

ZCC = docker run --rm \
	-v $(CURDIR):/work \
	-v $(ZLOCAL):/z88dk-local/ \
	-v $(ZLOCAL)/config/mycron.cfg:$(ZCCCFG_IN_CONTAINER)/mycron.cfg:ro \
	-w /work \
	$(IMAGE) \
	zcc

TARGET   = +z80
COMPILER = -compiler=sccz80
ORG = -zorg=0x2000
STACK= -pragma-define:REGISTER_SP=0xfff0
INTR = -pragma-define:CRT_ENABLE_EIDI=0


CFLAGS   = $(TARGET) $(COMPILER) -O3 -vn -nostdlib $(ORG) $(STACK) $(INTR)
CRT0     = -crt0=crt0_mycron.asm
SOURCES  = mycron_io.asm hello.c

all: hello.bin

# hello.bin: $(OBJS)
# 	$(ZCC) $(CFLAGS) -m -create-app -o hello $(OBJS)

hello.bin: crt0_mycron.asm mycron_io.asm hello.c mycron.h
	$(ZCC) $(CFLAGS) $(CRT0) -m -create-app -o hello $(SOURCES)

clean:
	rm -f *.o *.bin *.map *.lis *.sym hello hello_* zcc_opt.def


check:
	grep -E "main|mycron|REGISTER|Start" hello.map
	xxd -g1 -l32 hello.bin
