;;
;; BriefLZ  -  small fast Lempel-Ziv
;;
;; NASM 16-bit assembler packer
;;
;; Copyright (c) 2002-2003 by Joergen Ibsen / Jibz
;; All Rights Reserved
;;
;; http://www.ibsensoftware.com/
;;
;; This software is provided 'as-is', without any express
;; or implied warranty.  In no event will the authors be
;; held liable for any damages arising from the use of
;; this software.
;;
;; Permission is granted to anyone to use this software
;; for any purpose, including commercial applications,
;; and to alter it and redistribute it freely, subject to
;; the following restrictions:
;;
;; 1. The origin of this software must not be
;;    misrepresented; you must not claim that you
;;    wrote the original software. If you use this
;;    software in a product, an acknowledgment in
;;    the product documentation would be appreciated
;;    but is not required.
;;
;; 2. Altered source versions must be plainly marked
;;    as such, and must not be misrepresented as
;;    being the original software.
;;
;; 3. This notice may not be removed or altered from
;;    any source distribution.
;;

; must be a power of 2 (between 8k and 32k appear reasonable)
BLZ_WORKMEM_SIZE equ 32*1024

%if BLZ_WORKMEM_SIZE & (BLZ_WORKMEM_SIZE-1)
  %error BLZ_WORKMEM_SIZE must be a power of 2
%endif

cpu 8086

bits 16

section _TEXT class=CODE public use16 align=4

group DGROUP _DATA

global _blz16_workmem_size
global _blz16_max_packed_size
global _blz16_pack_asm

; =============================================================

_blz16_workmem_size:
    ; blz16_workmem_size(unsigned short length);

    mov    ax, BLZ_WORKMEM_SIZE

    ret

; =============================================================

_blz16_max_packed_size:
    ; blz16_max_packed_size(unsigned short length);

    .len$  equ 1*2 + 2

    push   bp

    mov    bp, sp

    mov    ax, [bp + .len$]   ; length + length/8 + 64
    mov    dx, ax
    shr    dx, 1
    shr    dx, 1
    shr    dx, 1
    add    ax, dx
    add    ax, byte 64

    pop    bp

    ret

; =============================================================

_blz16_pack_asm:
    ; blz16_pack_asm(const void far *source,
    ;                void far *destination,
    ;                unsigned short length,
    ;                void far *workmem);

    .wkm$  equ 6*2 + 2 + 10
    .len$  equ 6*2 + 2 + 8
    .dst$  equ 6*2 + 2 + 4
    .src$  equ 6*2 + 2

    .lim$  equ -2
    .bpt$  equ -4
    .tbp$  equ -6

    push   bx
    push   si
    push   di
    push   ds
    push   es
    push   bp

    mov    bp, sp

    sub    sp, byte 3*2       ; make room for temps

    cld

    les    di, [bp + .wkm$]   ; es:di -> lookuptable[]

    xor    ax, ax             ; clear lookuptable[]
    mov    cx, BLZ_WORKMEM_SIZE/2
    rep    stosw

    lds    si, [bp + .src$]   ; es:di -> source[]
    les    di, [bp + .dst$]   ; es:di -> destination[]
    mov    bx, [bp + .len$]

    lea    ax, [bx + si - 4]  ; limit = source + length - 4
    mov    [bp + .lim$], ax   ;

    mov    [bp + .bpt$], si   ; backptr = source

    test   bx, bx             ; length == 0?
    jz     short .jmptodone   ;

    movsb                     ; fist byte verbatim

    cmp    bx, byte 1         ; only one byte?
    jne    short .morethan1   ;
  .jmptodone:                 ;
    jmp    near .EODdone      ;
  .morethan1:                 ;

    xor    dx, dx             ; initialise tag
    inc    dx                 ;
    mov    [bp + .tbp$], di   ;
    add    di, byte 2         ;

    jmp    short .nexttag

  .no_match:
    clc
    call   putbit             ; 0-bit = literal

    movsb                     ; copy literal

  .nexttag:
    cmp    si, [bp + .lim$]   ; are we done?
    jae    short .donepacking ;

    push   es
    push   di

    les    di, [bp + .wkm$]   ; es:di -> lookuptable[]

    mov    bx, si             ; bx = buffer - backptr
    xchg   si, [bp + .bpt$]   ; i.e. distance from backptr to current
    sub    bx, si             ; (also stores new backptr)

  .update:
    call   hash4              ; hash next 4 bytes

    add    di, ax
    mov    [es:di], si        ; lookuptable[hash] = backptr
    sub    di, ax

    inc    si                 ; ++backptr
    dec    bx
    jnz    short .update      ; when done, si is back to current pos

    call   hash4              ; hash next 4 bytes

    add    di, ax
    mov    bx, [es:di]        ; bx = lookuptable[hash]

    pop    di
    pop    es

    test   bx, bx             ; no match?
    jz     short .no_match    ;

    ; check match length
    mov    cx, [bp + .lim$]   ; cx = max allowed match length
    sub    cx, si             ;
    add    cx, byte 4         ;

    push   si
    push   di
    push   es

    push   ds
    pop    es

    mov    di, bx

    xor    ax, ax
  .compare:
    cmpsb                     ; compare possible match with current
    jne    short .matchlen_found

    inc    ax

    dec    cx
    jnz    short .compare

  .matchlen_found:
    pop    es
    pop    di
    pop    si

    cmp    ax, byte 4         ; match too short?
    jb     short .no_match    ;

    mov    cx, si             ;
    sub    cx, bx             ; cx = matchpos

    call   putbit1            ; 1-bit = match

    add    si, ax             ; update si to next position

    sub    ax, byte 2         ; matchlen >= 4, so subtract 2

    call   putgamma           ; output gamma coding of matchlen - 2

    dec    cx                 ; matchpos > 0, so subtract 1

    xor    ax, ax             ; ax = (matchpos >> 8) + 2
    mov    al, ch             ;
    add    ax, byte 2         ;

    call   putgamma           ; output gamma coding of (matchpos >> 8) + 2

    xchg   ax, cx             ; output low 8 bits of matchpos
    stosb                     ;

    jmp    short .nexttag

  .donepacking:

    mov    bx, [bp + .lim$]   ; bx = source + length
    add    bx, byte 4         ;

    jmp    short .check_final_literals

  .final_literals:
    clc
    call   putbit             ; 0-bit = literal

    movsb                     ; copy literal

  .check_final_literals:
    cmp    si, bx
    jb     short .final_literals

    test   dx, dx             ; do we need to fix the last tag?
    jz     short .EODdone     ;

  .doEOD:
    add    dx, dx             ; shift last tag into position
    jnc    short .doEOD       ;

    push   di
    mov    di, [bp + .tbp$]
    mov    [es:di], dx        ; and put it into it's place
    pop    di

  .EODdone:
    mov    ax, di             ; return packed length in ax
    sub    ax, [bp + .dst$]   ;

    mov    sp, bp

    pop    bp
    pop    es
    pop    ds
    pop    di
    pop    si
    pop    bx

    ret

; =============================================================

putbit1:                      ; add 1-bit
    stc
putbit:                       ; add bit according to carry
    pushf
    test   dx, dx
    jnz    short .bitsleft
    mov    [bp + -6], di
    inc    dx
    add    di, byte 2
  .bitsleft:
    popf
    adc    dx, dx
    jnc    short .done
    push   di
    mov    di, [bp + -6]
    mov    [es:di], dx
    pop    di
    xor    dx, dx
  .done:
    ret

putgamma:                     ; output gamma coding of value in ax
    push   bx                 ; (ax > 1)
    push   ax
    shr    ax, 1
    xor    bx, bx
    inc    bx
  .revmore:
    shr    ax, 1
    jz     short .outstart
    adc    bx, bx
    jmp    short .revmore
  .outmore:
    call   putbit
    call   putbit1
  .outstart:
    shr    bx, 1
    jnz    short .outmore
    pop    ax
    shr    ax, 1
    call   putbit
    call   putbit             ; CF = 0 from call above
    pop    bx
    ret

hash4:                        ; hash next 4 bytes into ax
    push   cx
    push   dx
    xor    ax, ax
    mov    al, [si]
    mov    dx, 317
    imul   dx
    xor    cx, cx
    mov    cl, [si+1]
    add    ax, cx
    mov    dx, 317
    imul   dx
    mov    cl, [si+2]
    add    ax, cx
    mov    dx, 317
    imul   dx
    mov    cl, [si+3]
    add    ax, cx
    and    ax, (BLZ_WORKMEM_SIZE/2)-1
    pop    dx
    pop    cx
    add    ax, ax
    ret

; =============================================================

section _DATA class=DATA public use16 align=4

; =============================================================
