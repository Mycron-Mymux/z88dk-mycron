        MODULE  mycron_bldr

        SECTION code_clib

        defc    MYCROP_BLDR = 0082h

        PUBLIC  _mycron_bldr
        EXTERN  mycron_disk_setup_sector_params

; unsigned char mycron_bldr(mycron_sector_io_t *p) __z88dk_fastcall;
_mycron_bldr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BLDR
        ld      l,a
        ld      h,0
        ret

