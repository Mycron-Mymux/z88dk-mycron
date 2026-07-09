        MODULE  mycron_bdc

        SECTION code_clib

        defc    MYCROP_BDC = 007Ch

        PUBLIC  _mycron_bdc

; ------------------------------------------------------------
; unsigned char mycron_bdo(unsigned char unit) __z88dk_fastcall;
;
; L = unit
; returns status in HL
; ------------------------------------------------------------
_mycron_bdc:
        ld      a,l
        call    MYCROP_BDC
        ld      l,a
        ld      h,0
        ret

