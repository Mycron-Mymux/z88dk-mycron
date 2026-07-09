        MODULE  mycron_bddr

        SECTION code_clib

        defc    MYCROP_BDDR = 0079h

        PUBLIC  _mycron_bddr
        EXTERN  mycron_disk_setup_sector_params

; ------------------------------------------------------------
; unsigned char mycron_bddr(mycron_sector_io_t *p) __z88dk_fastcall;
; ------------------------------------------------------------

_mycron_bddr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BDDR
        ld      l,a
        ld      h,0
        ret

