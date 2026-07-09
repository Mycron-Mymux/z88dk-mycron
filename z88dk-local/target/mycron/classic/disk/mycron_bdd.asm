        MODULE  mycron_bdd

        SECTION code_clib

        defc    MYCROP_BDD = 007Fh

        PUBLIC  _mycron_bdd

; unsigned char mycron_bdd(unsigned char unit) __z88dk_fastcall;
_mycron_bdd:
        ld      a,l
        call    MYCROP_BDD
        ld      l,a
        ld      h,0
        ret

