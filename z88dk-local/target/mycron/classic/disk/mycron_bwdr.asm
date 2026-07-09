        MODULE  mycron_bwdr

        SECTION code_clib

        defc    MYCROP_BWDR = 0076h

        PUBLIC  _mycron_bwdr
        EXTERN  mycron_disk_setup_sector_params
       
; ------------------------------------------------------------
; unsigned char mycron_bwdr(mycron_sector_io_t *p) __z88dk_fastcall;
; ------------------------------------------------------------

_mycron_bwdr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BWDR
        ld      l,a
        ld      h,0
        ret

