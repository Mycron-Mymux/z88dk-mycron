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

