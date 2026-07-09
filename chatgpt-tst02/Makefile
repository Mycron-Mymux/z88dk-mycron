ZCC      = zcc
TARGET   = +z80
COMPILER = -compiler=sccz80

CLIB= -clib=classic
ORG = -zorg=0x3000
STACK= -pragma-define:REGISTER_SP=0xfff0
INTR = -pragma-define:CRT_ENABLE_EIDI=0

REDIRECTS = \
    -pragma-redirect:fputc_cons=mycron_fputc_cons \
    -pragma-redirect:fgetc_cons=mycron_fgetc_cons \
    -pragma-redirect:getk=mycron_getk \
    -pragma-redirect:getkey=mycron_getkey

CFLAGS   = $(TARGET) $(COMPILER) -O3 -vn $(ORG) $(STACK) $(INTR)
CRT0     = -crt0=crt0_mycron.asm
SOURCES1  = mycron_io.asm hello.c
SOURCES2  = mycron_stdio.asm hello_std.c

all: hello.bin hello_std.bin

# hello.bin: $(OBJS)
# 	$(ZCC) $(CFLAGS) -m -create-app -o hello $(OBJS)

hello.bin: crt0_mycron.asm mycron_io.asm hello.c mycron.h
	$(ZCC) $(CFLAGS) -nostdlib $(CRT0) -m -create-app -o hello $(SOURCES1)

hello_std.bin: $(SOURCES2)
	$(ZCC) $(CLIB)  $(CFLAGS) $(REDIRECTS) -m -create-app -o hello_std $(SOURCES2)

clean:
	rm -f *.o *.bin *.map *.lis *.sym hello_std hello zcc_opt.def


check:
	grep -E "main|mycron|REGISTER|Start" hello.map
	xxd -g1 -l32 hello.bin

check_std:
	grep -E "main|mycron|REGISTER|Start" hello_std.map
	xxd -g1 -l32 hello_std.bin
