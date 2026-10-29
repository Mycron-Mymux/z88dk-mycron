; mycron_io.asm
;
; Small C-callable wrappers around MYCROP console routines.
;
; C prototypes are in mycron.h.

        MODULE  mycron_io

        SECTION code_user

        defc    MYCROP_MON      = 0040h
        defc    MYCROP_POLL     = 0046h
        defc    MYCROP_CRLF     = 0049h
        defc    MYCROP_TTCON    = 004Ch
        defc    MYCROP_TTCLF    = 004Fh
        defc    MYCROP_TTI      = 0052h
        defc    MYCROP_TTIO     = 0055h
        defc    MYCROP_TTO      = 0058h

        PUBLIC  _mycron_putchar
        PUBLIC  _mycron_puts
        PUBLIC  _mycron_puts_crlf
        PUBLIC  _mycron_crlf
        PUBLIC  _mycron_getchar
        PUBLIC  _mycron_getchar_echo
        PUBLIC  _mycron_pollchar
        PUBLIC  _mycron_exit_to_monitor
        PUBLIC  _mycron_di
        PUBLIC  _mycron_ei

; ------------------------------------------------------------
; void mycron_putchar(unsigned char ch) __z88dk_fastcall;
;
; Entry:
;   L = character
; ------------------------------------------------------------
_mycron_putchar:
        ld      a,l
        call    MYCROP_TTO
        ret


; ------------------------------------------------------------
; void mycron_puts(const char *s) __z88dk_fastcall;
;
; Entry:
;   HL = pointer to NUL-terminated string
;
; MYCROP TTCON expects:
;   BC = pointer
; ------------------------------------------------------------
_mycron_puts:
        ld      b,h
        ld      c,l
        call    MYCROP_TTCON
        ret


; ------------------------------------------------------------
; void mycron_puts_crlf(const char *s) __z88dk_fastcall;
;
; Entry:
;   HL = pointer to NUL-terminated string
;
; MYCROP TTCLF prints string and then CR/LF.
; ------------------------------------------------------------
_mycron_puts_crlf:
        ld      b,h
        ld      c,l
        call    MYCROP_TTCLF
        ret


; ------------------------------------------------------------
; void mycron_crlf(void);
; ------------------------------------------------------------
_mycron_crlf:
        call    MYCROP_CRLF
        ret


; ------------------------------------------------------------
; int mycron_getchar(void);
;
; Blocking input, no echo.
;
; Return:
;   HL = character, 0..127
; ------------------------------------------------------------
_mycron_getchar:
        call    MYCROP_TTI
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; int mycron_getchar_echo(void);
;
; Blocking input, with echo.
;
; Return:
;   HL = character, 0..127
; ------------------------------------------------------------
_mycron_getchar_echo:
        call    MYCROP_TTIO
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; int mycron_pollchar(void);
;
; Nonblocking input.
;
; Return:
;   HL = character 0..127 if available
;   HL = -1 if no character available
;
; MYCROP poll_read_con:
;   Z set    = no char
;   NZ set   = char in A
; ------------------------------------------------------------
_mycron_pollchar:
        call    MYCROP_POLL
        jr      z,__no_char

        ld      l,a
        ld      h,0
        ret

__no_char:
        ld      hl,0FFFFh
        ret


; ------------------------------------------------------------
; void mycron_exit_to_monitor(void);
;
; Does not return unless user uses monitor return facilities.
; ------------------------------------------------------------
_mycron_exit_to_monitor:
        jp      MYCROP_MON



_mycron_di:
        di
        ret

_mycron_ei:
        ei
        ret
