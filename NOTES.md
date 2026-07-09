@ 2026-07-09 torsdag 03:00
---------------------------

/src # echo $ZCCCFG
/opt/z88dk/lib/config/

/src # cp -a $ZCCCFG/* z88dk-local/config/ 
create
z88dk-local/target/mycron/classic/mycron_stdio.asm


need to add to shell
export ZCCCFG="$PWD/z88dk-local/config"
export ZCCCFG="/z88dk-local/config"
and -v  xxx:/z88dk-local

env kan settes i docker command. 

docker run --rm -it -v "$(pwd)":/src -v "$(pwd)"/z88dk-local:/z88dk-local -e ZCCCFG=/z88dk-local/config z88dk/z88dk sh

@ 2026-07-09 torsdag 14:25
---------------------------


z88dk-local/target/mycron/include/mycron_disk.h
z88dk-local/target/mycron/include/mycron_alloc.h
z88dk-local/target/mycron/classic/mycron_disk.asm
z88dk-local/target/mycron/classic/mycron_disk.c
z88dk-local/target/mycron/classic/mycron_alloc.c

