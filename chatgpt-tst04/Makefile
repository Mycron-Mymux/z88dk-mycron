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

CFLAGS = +mycron -O3 -vn -m -create-app

TARGS = disk_test prog_load alloc_test

all: $(TARGS)

% : %.c
	$(ZCC) $(CFLAGS) $< -o $@ 

clean:
	rm -f *.o *.bin *.map *.lis *.sym $(TARGS) hello_* zcc_opt.def
