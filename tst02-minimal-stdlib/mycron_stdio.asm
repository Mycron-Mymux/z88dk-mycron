; mycron_stdio.asm
;
; Mycron/MYCROP console routines for z88dk classic stdio.
;
; These are deliberately NOT called fputc_cons/fgetc_cons/getk/getkey,
; because the generic +z80 CRT already defines those symbols.
;
; The build command redirects:
;
;   fputc_cons -> mycron_fputc_cons
;   fgetc_cons -> mycron_fgetc_cons
;   getk       -> mycron_getk
;   getkey     -> mycron_getkey

        MODULE  mycron_stdio

        SECTION code_clib

        defc    MYCROP_MON      = 0040h
        defc    MYCROP_POLL     = 0046h
        defc    MYCROP_TTI      = 0052h
        defc    MYCROP_TTO      = 0058h

        PUBLIC  mycron_fputc_cons
        PUBLIC  mycron_fgetc_cons
        PUBLIC  mycron_getk
        PUBLIC  mycron_getkey

        PUBLIC  _mycron_exit_to_monitor


; ------------------------------------------------------------
; mycron_fputc_cons
;
; Replacement for classic fputc_cons.
;
; Character argument is on stack at SP+2.
;
; Converts '\n' to CR/LF.
; ------------------------------------------------------------

mycron_fputc_cons:
        ld      hl,2
        add     hl,sp
        ld      a,(hl)

        cp      10              ; '\n'
        jr      nz,mycron_fputc_not_lf

        ld      a,13            ; '\r'
        call    MYCROP_TTO
        ld      a,10            ; '\n'
        call    MYCROP_TTO
        ret

mycron_fputc_not_lf:
        call    MYCROP_TTO
        ret


; ------------------------------------------------------------
; mycron_fgetc_cons
;
; Replacement for classic fgetc_cons.
;
; Blocking read.
; Echoes input manually.
; Converts CR to '\n'.
; ------------------------------------------------------------

mycron_fgetc_cons:
        call    MYCROP_TTI      ; blocking input, no echo

        cp      13              ; CR?
        jr      nz,mycron_fgetc_not_cr

        ld      a,13
        call    MYCROP_TTO
        ld      a,10
        call    MYCROP_TTO

        ld      hl,10           ; return '\n'
        ret

mycron_fgetc_not_cr:
        push    af
        call    MYCROP_TTO      ; echo character
        pop     af

        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; mycron_getk
;
; Replacement for classic getk.
;
; Nonblocking key poll.
;
; Return:
;   HL = 0 if no key
;   HL = character otherwise
; ------------------------------------------------------------

mycron_getk:
        call    MYCROP_POLL
        jr      z,mycron_getk_no_key

        cp      13
        jr      nz,mycron_getk_not_cr
        ld      a,10

mycron_getk_not_cr:
        ld      l,a
        ld      h,0
        ret

mycron_getk_no_key:
        ld      hl,0
        ret


; ------------------------------------------------------------
; mycron_getkey
;
; Replacement for classic getkey.
;
; Blocking, no echo.
; Converts CR to '\n'.
; ------------------------------------------------------------

mycron_getkey:
        call    MYCROP_TTI

        cp      13
        jr      nz,mycron_getkey_not_cr
        ld      a,10

mycron_getkey_not_cr:
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; void mycron_exit_to_monitor(void);
; ------------------------------------------------------------

_mycron_exit_to_monitor:
        jp      MYCROP_MON

