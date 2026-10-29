        MODULE  mycron_calls

        SECTION code_clib

        defc    MYCROP_U8_to_BCD = 00afh

        PUBLIC  _mycron_u8_to_bcd

; unsigned char mycron_u2_to_bcd(unsigned char val) __z88dk_fastcall;
; Input: A
; Output: 
; - D - hundreds digit
; - E - BCD of tens/ones
_mycron_u8_to_bcd:
        ld      a,l
        call    MYCROP_U8_to_BCD
        ld      l,E
        ld      h,D
        ret

