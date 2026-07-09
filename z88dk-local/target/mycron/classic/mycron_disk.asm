; mycron_disk.asm
;
; C wrappers for MYCROP disk services.
;
; These are low-level monitor wrappers. Higher-level convenience
; functions are implemented in mycron_disk.c.
;
; z88dk/sccz80 C symbols have leading underscores.
;
; Functions using __z88dk_fastcall receive their single argument in HL.

        MODULE  mycron_disk

        SECTION code_clib

        defc    MYCROP_LOAD     = 006Dh
        defc    MYCROP_BDO      = 0070h
        defc    MYCROP_BRDR     = 0073h
        defc    MYCROP_BWDR     = 0076h
        defc    MYCROP_BDDR     = 0079h
        defc    MYCROP_BDC      = 007Ch
        defc    MYCROP_BDD      = 007Fh
        defc    MYCROP_BLDR     = 0082h
        defc    MYCROP_BUDR     = 0085h
        defc    MYCROP_LINK     = 0088h

        PUBLIC  _mycron_bdo
        PUBLIC  _mycron_bdc
        PUBLIC  _mycron_bdd

        PUBLIC  _mycron_bldr
        PUBLIC  _mycron_budr
        PUBLIC  _mycron_brdr
        PUBLIC  _mycron_bwdr
        PUBLIC  _mycron_bddr

        PUBLIC  _mycron_load
        PUBLIC  _mycron_link


; ------------------------------------------------------------
; unsigned char mycron_bdo(unsigned char unit) __z88dk_fastcall;
;
; L = unit
; returns status in HL
; ------------------------------------------------------------

_mycron_bdo:
        ld      a,l
        call    MYCROP_BDO
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; unsigned char mycron_bdc(unsigned char unit) __z88dk_fastcall;
; ------------------------------------------------------------

_mycron_bdc:
        ld      a,l
        call    MYCROP_BDC
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; unsigned char mycron_bdd(unsigned char unit) __z88dk_fastcall;
; ------------------------------------------------------------

_mycron_bdd:
        ld      a,l
        call    MYCROP_BDD
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; Common setup for sector I/O parameter block.
;
; Input:
;   HL = pointer to mycron_sector_io_t
;
; Output:
;   A  = unit
;   B  = track
;   C  = sector
;   D  = bad74
;   E  = bad75
;   HL = buffer address
;
; Struct layout:
;   +0 unit
;   +1 track
;   +2 sector
;   +3 bad74
;   +4 bad75
;   +5 addr low
;   +6 addr high
; ------------------------------------------------------------

mycron_disk_setup_sector_params:
        push    ix
        push    hl
        pop     ix

        ld      a,(ix+0)
        ld      b,(ix+1)
        ld      c,(ix+2)
        ld      d,(ix+3)
        ld      e,(ix+4)
        ld      l,(ix+5)
        ld      h,(ix+6)

        pop     ix
        ret


; ------------------------------------------------------------
; unsigned char mycron_bldr(mycron_sector_io_t *p) __z88dk_fastcall;
;
; Raw 128-byte sector read.
; ------------------------------------------------------------

_mycron_bldr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BLDR
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; unsigned char mycron_budr(mycron_sector_io_t *p) __z88dk_fastcall;
;
; Raw 128-byte sector write.
; ------------------------------------------------------------

_mycron_budr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BUDR
        ld      l,a
        ld      h,0
        ret


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


; ------------------------------------------------------------
; unsigned char mycron_bwdr(mycron_sector_io_t *p) __z88dk_fastcall;
; ------------------------------------------------------------

_mycron_bwdr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BWDR
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; unsigned char mycron_bddr(mycron_sector_io_t *p) __z88dk_fastcall;
; ------------------------------------------------------------

_mycron_bddr:
        call    mycron_disk_setup_sector_params
        call    MYCROP_BDDR
        ld      l,a
        ld      h,0
        ret


; ------------------------------------------------------------
; unsigned char mycron_load(mycron_load_params_t *p) __z88dk_fastcall;
;
; Struct layout:
;
;   +0 unit
;   +1 name8 pointer low
;   +2 name8 pointer high
;   +3 entry low
;   +4 entry high
;
; MYCROP LOAD:
;
;   A  = unit
;   BC = pointer to 8-byte, space-padded program name
;
; Return:
;
;   carry clear: success, HL = entry
;   carry set:   error, A = error code
;
; This wrapper:
;
;   returns 0 on success
;   returns MYCROP error code on failure
;   stores entry address into p->entry on success
; ------------------------------------------------------------

_mycron_load:
        push    ix
        push    hl
        pop     ix

        ld      a,(ix+0)
        ld      c,(ix+1)
        ld      b,(ix+2)

        call    MYCROP_LOAD

        jr      c,mycron_load_error

        ; success: store returned HL into p->entry
        ld      (ix+3),l
        ld      (ix+4),h

        xor     a

mycron_load_error:
        ld      l,a
        ld      h,0
        pop     ix
        ret


; ------------------------------------------------------------
; unsigned char mycron_link(mycron_load_params_t *p) __z88dk_fastcall;
;
; MYCROP LINK:
;
;   A  = unit
;   BC = pointer to 8-byte, space-padded program name
;
; LINK does not return on success.
; It returns only on error with carry set and A = error code.
; ------------------------------------------------------------

_mycron_link:
        push    ix
        push    hl
        pop     ix

        ld      a,(ix+0)
        ld      c,(ix+1)
        ld      b,(ix+2)

        call    MYCROP_LINK

        ; If LINK returned, it failed.
        ; Return A as status.
        ld      l,a
        ld      h,0

        pop     ix
        ret

