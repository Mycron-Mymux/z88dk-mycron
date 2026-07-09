        MODULE  mycron_link

        SECTION code_clib

        defc    MYCROP_LINK = 0088h

        PUBLIC  _mycron_link

; unsigned char mycron_link(mycron_load_params_t *p) __z88dk_fastcall;
;
; Does not return on success.
; Returns error code on failure.

_mycron_link:
        push    ix
        push    hl
        pop     ix

        ld      a,(ix+0)
        ld      c,(ix+1)
        ld      b,(ix+2)

        call    MYCROP_LINK

        ; If LINK returned, it failed.
        ld      l,a
        ld      h,0

        pop     ix
        ret

