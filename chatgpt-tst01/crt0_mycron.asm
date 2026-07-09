; crt0_mycron.asm
;
; Minimal crt0 for Mycron/MYCROP using z88dk.
;
; Program load/start address: 0800h
; Suggested monitor command:  G0800
;
; RAM note:
;   Old documentation says user RAM is roughly 0800h..0BE3h,
;   with monitor/breakpoint/interrupt workspace above that.
;   Therefore this uses 0BE4h as the initial stack.
;
; If your machine really has free RAM up to 0FCFh, you can move
; MYCRON_STACK upward, but do not overwrite 0FD0h..0FFFh since
; MYCROP uses that area.

        MODULE  crt0_mycron

        SECTION code_crt_init

        ; JMB: makes more sense to use the full 64K memory
        ; defc    MYCRON_ORG      = 0800h
        ; defc    MYCRON_STACK    = 0BE4h
        defc    MYCRON_ORG      = 03000h
        defc    MYCRON_STACK    = 0FFF0h

        defc    MYCROP_MON      = 0040h

        PUBLIC  __Start
        PUBLIC  start
        PUBLIC  _start

        PUBLIC  cleanup
        
        EXTERN  _main

        ; use -zorg=0x3000 instead
        ; org     MYCRON_ORG

__Start:
start:
_start:
        ; Optional: leave interrupts as monitor configured them.
        ; If your application does not handle interrupts, you may want:
        ; di

        ld      sp, MYCRON_STACK

        call    _main

cleanup:
        ; Return to MYCROP monitor.
        jp      MYCROP_MON

