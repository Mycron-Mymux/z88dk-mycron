        MODULE  mycron_disk_setup_sector_params

        SECTION code_clib

        PUBLIC  mycron_disk_setup_sector_params

; Internal helper.
;
; Input:
;   HL = mycron_sector_io_t *
;
; Output:
;   A  = unit
;   B  = track
;   C  = sector
;   D  = bad74
;   E  = bad75
;   HL = buffer address
;
; Struct:
;   +0 unit
;   +1 track
;   +2 sector
;   +3 bad74
;   +4 bad75
;   +5 addr low
;   +6 addr high

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

