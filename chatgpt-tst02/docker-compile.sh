docker run --rm -v "$(pwd)":/src  -w /src z88dk/z88dk \
       zcc +z80 -compiler=sccz80 -O3 -vn -nostdlib -m -zorg=0x2000 -create-app \
       -crt0=crt0_mycron.asm   \
       -pragma-define:REGISTER_SP=0xfff0 \
       -pragma-define:CRT_ENABLE_EIDI=0 \
       -o hello  mycron_io.asm hello.c
