Yes. z88dk supports inline assembly, but the exact syntax depends on which compiler frontend you use.

For your current setup, you are using:

```sh
-compiler=sccz80
```

so the relevant syntax is the **sccz80** inline assembly syntax.

---

# 1. sccz80 inline assembly

With `sccz80`, use:

```c
#asm
    ; z80 assembly here
#endasm
```

Example:

```c
void my_di(void)
{
#asm
    di
#endasm
}
```

Another example:

```c
void my_ei(void)
{
#asm
    ei
#endasm
}
```

---

# 2. Simple MYCROP call example

For example, output a character through MYCROP `TTO` at `0058h`:

```c
void my_put_a(void)
{
#asm
    ld a,'A'
    call 0058h
#endasm
}
```

Call from C:

```c
int main(void)
{
    my_put_a();
    return 0;
}
```

---

# 3. Function argument example

For normal C functions using `sccz80`, arguments are generally passed on the stack, so reading them manually in inline assembly is possible but awkward.

For single-argument small functions, you can use `__z88dk_fastcall`, where the argument is passed in `HL`.

Example:

```c
void my_putchar_fast(unsigned char ch) __z88dk_fastcall
{
#asm
    ld a,l
    call 0058h
#endasm
}
```

Then:

```c
my_putchar_fast('X');
```

This is much easier than manually extracting the argument from the stack.

---

# 4. Returning a value

For many z88dk C functions, integer return values are returned in `HL`.

Example: return `0x1234`:

```c
unsigned int get_magic(void)
{
#asm
    ld hl,01234h
#endasm
}
```

Example: call MYCROP `TTI` and return the character:

```c
int my_getchar_noecho(void)
{
#asm
    call 0052h      ; TTI
    ld l,a
    ld h,0
#endasm
}
```

---

# 5. Nonblocking poll example

MYCROP `poll_read_con` at `0046h` returns:

- `Z` set if no character
- `NZ` and `A = char` if a character is available

A C wrapper returning `-1` if no character:

```c
int my_pollchar(void)
{
#asm
    call 0046h
    jr z,my_pollchar_no_key

    ld l,a
    ld h,0
    ret

my_pollchar_no_key:
    ld hl,0ffffh
#endasm
}
```

Note: this inline assembly includes a `ret`. That is allowed, but be careful. If you put `ret` inside inline asm, you are bypassing any compiler-generated epilogue for that function. For simple functions this is usually okay, but it can be dangerous if the compiler has emitted setup code.

Safer version without explicit `ret`:

```c
int my_pollchar(void)
{
#asm
    call 0046h
    jr z,my_pollchar_no_key

    ld l,a
    ld h,0
    jr my_pollchar_done

my_pollchar_no_key:
    ld hl,0ffffh

my_pollchar_done:
#endasm
}
```

---

# 6. Labels in inline assembly

Avoid short generic labels like:

```asm
loop:
done:
```

because they may collide if the function is included more than once or if other code uses the same label.

Use unique names:

```c
int my_pollchar(void)
{
#asm
    call 0046h
    jr z,my_pollchar_no_key_001

    ld l,a
    ld h,0
    jr my_pollchar_done_001

my_pollchar_no_key_001:
    ld hl,0ffffh

my_pollchar_done_001:
#endasm
}
```

Since your assembler disliked `.local` labels earlier, globally unique labels are the safest approach.

---

# 7. Preserving registers

Inline assembly can clobber registers. The compiler may assume some registers survive depending on context.

For very small whole-function wrappers, it is normally okay to set the return value in `HL` and clobber `AF`.

For inline assembly inside larger C functions, be conservative:

```c
void example(void)
{
#asm
    push bc
    push de
    push ix
    push iy

    ; your assembly here

    pop iy
    pop ix
    pop de
    pop bc
#endasm
}
```

But do **not** blindly push/pop `HL` if you are trying to return a value in `HL`.

---

# 8. Best practice for your Mycron target

For reusable runtime functions, prefer separate `.asm` files:

```text
mycron_stdio.asm
mycron_disk.asm
```

That is cleaner, easier to debug, and avoids inline assembly calling convention surprises.

Use inline assembly for:

- tiny experiments
- one-off port access
- `di` / `ei`
- calling a monitor function during testing
- tight hardware routines

---

# 9. Example: inline port I/O

```c
unsigned char in_port_14(void)
{
#asm
    in a,(014h)
    ld l,a
    ld h,0
#endasm
}
```

```c
void out_port_14(unsigned char value) __z88dk_fastcall
{
#asm
    ld a,l
    out (014h),a
#endasm
}
```

---

# 10. If using `zsdcc`

If you later switch to:

```sh
-compiler=sdcc
```

or z88dk’s SDCC frontend, the inline assembly syntax is different, typically SDCC-style:

```c
void f(void)
{
__asm
    di
__endasm;
}
```

But for your current `sccz80` setup, use:

```c
#asm
#endasm
```

---

# Summary

Yes, z88dk supports inline assembly.

For your current `sccz80` setup:

```c
#asm
    ld a,'A'
    call 0058h
#endasm
```

Use `__z88dk_fastcall` for simple argument passing:

```c
void my_putchar_fast(unsigned char ch) __z88dk_fastcall
{
#asm
    ld a,l
    call 0058h
#endasm
}
```

For reusable Mycron runtime code, separate `.asm` files are still the better long-term choice.

