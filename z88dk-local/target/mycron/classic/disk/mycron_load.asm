        MODULE  mycron_load

        SECTION code_clib

        defc    MYCROP_LOAD = 006Dh

        PUBLIC  _mycron_load

; unsigned char mycron_load(mycron_load_params_t *p) __z88dk_fastcall;
;
; Struct:
;   +0 unit
;   +1 name8 pointer low
;   +2 name8 pointer high
;   +3 entry low
;   +4 entry high
;
; Returns:
;   0 on success, p->entry set
;   error code on failure

_mycron_load:
        push    ix
        push    hl
        pop     ix

        ld      a,(ix+0)
        ld      c,(ix+1)
        ld      b,(ix+2)

        call    MYCROP_LOAD

        jr      c,mycron_load_error

        ld      (ix+3),l
        ld      (ix+4),h

        xor     a

mycron_load_error:
        ld      l,a
        ld      h,0
        pop     ix
        ret

