#!/bin/bash

# Fix: don't do the -e to override the env var. Point the config file into there instead.
#       -e ZCCCFG=/z88dk-local/config \
#        -I/z88dk-local/target/mycron/include \
#       -v $Z88LOCAL/target/mycron/include/mycron.h:/opt/z88dk/include/mycron.h:ro \

Z88LOCAL="$(pwd)/../z88dk-local"

compile1() {
docker run --rm \
       -v "$(pwd)":/src \
       -v $Z88LOCAL:/z88dk-local \
       -v $Z88LOCAL/config/mycron.cfg:/opt/z88dk/lib/config/mycron.cfg:ro \
       -w /src z88dk/z88dk \
       zcc +mycron -clib=classic -O3 -vn -m -create-app \
       -zorg=0x3000 \
       -pragma-define:REGISTER_SP=0xfff0 \
       -pragma-define:CRT_ENABLE_EIDI=0 \
       -I/z88dk-local/target/mycron/include \
       -pragma-redirect:fputc_cons=mycron_fputc_cons \
       -pragma-redirect:fgetc_cons=mycron_fgetc_cons \
       -pragma-redirect:getk=mycron_getk \
       -pragma-redirect:getkey=mycron_getkey \
       -o hello hello.c \
       /z88dk-local/target/mycron/classic/mycron_stdio.asm
}
compile1b() {
docker run --rm \
       -v "$(pwd)":/src \
       -v $Z88LOCAL:/z88dk-local \
       -v $Z88LOCAL/config/mycron.cfg:/opt/z88dk/lib/config/mycron.cfg:ro \
       -w /src z88dk/z88dk \
       zcc +mycron -O3 -vn -m -create-app \
        -zorg=0x3000 \
       -pragma-define:REGISTER_SP=0xfff0 \
       -pragma-define:CRT_ENABLE_EIDI=0 \
       -I/z88dk-local/target/mycron/include \
       -pragma-redirect:fputc_cons=mycron_fputc_cons \
       -pragma-redirect:fgetc_cons=mycron_fgetc_cons \
       -pragma-redirect:getk=mycron_getk \
       -pragma-redirect:getkey=mycron_getkey \
       -o hello hello.c \
       /z88dk-local/target/mycron/classic/mycron_stdio.asm
}
compile2() {
docker run --rm \
       -v "$(pwd)":/src \
       -v $Z88LOCAL:/z88dk-local \
       -v $Z88LOCAL/config/mycron.cfg:/opt/z88dk/lib/config/mycron.cfg:ro \
       -w /src \
       z88dk/z88dk \
       zcc +mycron -O3 -vn -m -create-app \
       -o hello hello.c 

}

tst1() {
docker run --rm \
       -v "$(pwd)":/src \
       -v $Z88LOCAL:/z88dk-local \
       -v $Z88LOCAL/config/mycron.cfg:/opt/z88dk/lib/config/mycron.cfg:ro \
       -w /src z88dk/z88dk \
       sh -lc 'echo ZCCCFG=$ZCCCFG; echo "--- mycron.cfg tail ---"; tail -80 "$ZCCCFG/mycron.cfg"'
}

tst2() {
docker run --rm \
       -v "$(pwd)":/src \
       -v $Z88LOCAL:/z88dk-local \
       -v $Z88LOCAL/config/mycron.cfg:/opt/z88dk/lib/config/mycron.cfg:ro \
       -w /src z88dk/z88dk \
       zcc +mycron -v 
}

# tst1
#compile1b
compile2
# tst2
#       zcc +mycron  -vn
