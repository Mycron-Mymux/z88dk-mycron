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

CFLAGS = +mycron -O3 -vn -m -create-app # -Oz --opt-code-size

all: hello.bin

# hello.bin: examples/hello.c z88dk-local/config/mycron.cfg z88dk-local/target/mycron/classic/mycron_stdio.asm z88dk-local/target/mycron/include/mycron.h
# 	$(ZCC) $(CFLAGS) -o hello examples/hello.c
hello.bin: hello.c \
	    $(ZLOCAL)/config/mycron.cfg \
	    $(ZLOCAL)/target/mycron/classic/mycron_stdio.asm \
            $(ZLOCAL)/target/mycron/include/mycron.h
	$(ZCC) $(CFLAGS) -o hello hello.c

clean:
	rm -f *.o *.bin *.map *.lis *.sym hello hello_* zcc_opt.def
