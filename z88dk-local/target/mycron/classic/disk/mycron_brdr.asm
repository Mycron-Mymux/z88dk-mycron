        MODULE  mycron_brdr

        SECTION code_clib

        defc    MYCROP_BRDR = 0073h

        PUBLIC  _mycron_brdr
        EXTERN  mycron_disk_setup_sector_params

; ------------------------------------------------------------
; unsigned char mycron_brdr(mycron_sector_io_t *p) __z88dk_fastcall;
;
; Standard-format buffer read.
;
; MYCROP BRDR expects HL to point to a standard text buffer.
; The monitor itself skips the 3-byte buffer header before
; doing the raw read.
; ------------------------------------------------------------

_mycron_brdr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BRDR
        ld      l,a
        ld      h,0
        ret

