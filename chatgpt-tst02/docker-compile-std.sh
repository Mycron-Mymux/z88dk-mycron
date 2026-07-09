docker run --rm -v "$(pwd)":/src  -w /src z88dk/z88dk \
       zcc +z80 -clib=classic -compiler=sccz80 -O3 -vn  -zorg=0x2000 \
       -pragma-define:REGISTER_SP=0xfff0 \
       -pragma-define:CRT_ENABLE_EIDI=0 \
       -pragma-redirect:fputc_cons=mycron_fputc_cons \
       -pragma-redirect:fgetc_cons=mycron_fgetc_cons \
       -pragma-redirect:getk=mycron_getk \
       -pragma-redirect:getkey=mycron_getkey \
       -m -create-app \
       -o hello_std mycron_stdio.asm hello_std.c
