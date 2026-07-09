        MODULE  mycron_budr

        SECTION code_clib

        defc    MYCROP_BUDR = 0085h

        PUBLIC  _mycron_budr
        EXTERN  mycron_disk_setup_sector_params

; unsigned char mycron_budr(mycron_sector_io_t *p) __z88dk_fastcall;
_mycron_budr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BUDR
        ld      l,a
        ld      h,0
        ret

