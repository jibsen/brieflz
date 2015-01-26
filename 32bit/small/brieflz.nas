;;
;; BriefLZ  -  small fast Lempel-Ziv
;;
;; NASM small assembler packer
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

; must be a power of 2 (between 8k and 2mb appear reasonable)
BLZ_WORKMEM_SIZE equ 1024*1024

%if BLZ_WORKMEM_SIZE & (BLZ_WORKMEM_SIZE-1)
  %error BLZ_WORKMEM_SIZE must be a power of 2
%endif

cpu 386

bits 32

%include "nasmlcm.inc"

section lcmtext

lcmglobal blz_workmem_size,4
lcmglobal blz_max_packed_size,4
lcmglobal blz_pack_asm_small,16

lcmexport blz_workmem_size,4
lcmexport blz_max_packed_size,4
lcmexport blz_pack_asm_small,16

; =============================================================

lcmlabel blz_workmem_size,4
    ; blz_workmem_size(unsigned int length);

    mov    eax, BLZ_WORKMEM_SIZE

    lcmret 4

; =============================================================

lcmlabel blz_max_packed_size,4
    ; blz_max_packed_size(unsigned int length);

    .len$  equ 4

    mov    eax, [esp + .len$] ; length + length/8 + 64
    mov    edx, eax
    shr    edx, 3
    lea    eax, [eax + edx + 64]

    lcmret 4

; =============================================================

lcmlabel blz_pack_asm_small,16
    ; blz_pack_asm_small(const void *source,
    ;                    void *destination,
    ;                    unsigned int length,
    ;                    void *workmem);

    .wkm$  equ 2*4 + 4*4 + 4 + 12
    .len$  equ 2*4 + 4*4 + 4 + 8
    .dst$  equ 2*4 + 4*4 + 4 + 4
    .src$  equ 2*4 + 4*4 + 4

    .lim$  equ 4
    .bpt$  equ 0

    push   ebx
    push   esi
    push   edi
    push   ebp

    sub    esp, byte 2*4      ; make room for temps

    cld

    mov    edi, [esp + .wkm$] ; edi -> lookuptable[]

    xor    eax, eax           ; clear lookuptable[]
    mov    ecx, BLZ_WORKMEM_SIZE/4
    rep    stosd

    mov    esi, [esp + .src$]
    mov    edi, [esp + .dst$]
    mov    ebx, [esp + .len$]

    lea    eax, [ebx + esi - 4]
    mov    [esp + .lim$], eax ; limit = source + length - 4

    mov    [esp + .bpt$], esi ; backptr = source

    test   ebx, ebx           ; length == 0?
    jz     short .jmptodone   ;

    movsb                     ; fist byte verbatim

    cmp    ebx, byte 1        ; only one byte?
  .jmptodone:                 ;
    je     near .EODdone      ;

    xor    ebp, ebp           ; initialise tag
    inc    ebp                ;
    mov    edx, edi           ;
    add    edi, byte 2        ;

    jmp    short .nexttag

  .no_match:
    clc
    call   putbit             ; 0-bit = literal

    movsb                     ; copy literal

  .nexttag:
    cmp    esi, [esp + .lim$] ; are we done?
    jae    short .donepacking ;

    mov    ecx, [esp + .wkm$] ; ecx -> lookuptable[]

    mov    ebx, esi           ; ebx = buffer - backptr
    xchg   esi, [esp + .bpt$] ; i.e. distance from backptr to current
    sub    ebx, esi           ; (also stores new backptr)

  .update:
    call   hash4              ; hash next 4 bytes

    mov    [ecx + eax*4], esi ; lookuptable[hash] = backptr

    inc    esi                ; ++backptr
    dec    ebx
    jnz    short .update      ; when done, si is back to current pos

    call   hash4              ; hash next 4 bytes

    mov    ebx, [ecx + eax*4] ; ebx = lookuptable[hash]

    test   ebx, ebx           ; no match?
    jz     short .no_match    ;

    ; check match length
    mov    ecx, [esp + .lim$] ; ecx = max allowed match length
    sub    ecx, esi           ;
    add    ecx, byte 4        ;

    push   edx

    xor    eax, eax
  .compare:
    mov    dl, [ebx + eax]    ; compare possible match with current
    cmp    dl, [esi + eax]    ;
    jne    short .matchlen_found

    inc    eax

    dec    ecx
    jnz    short .compare

  .matchlen_found:
    pop    edx

    cmp    eax, byte 4        ; match too short?
    jb     short .no_match    ;

    mov    ecx, esi           ;
    sub    ecx, ebx           ; ecx = matchpos

    call   putbit1            ; 1-bit = match

    add    esi, eax           ; update esi to next position

    sub    eax, byte 2        ; matchlen >= 4, so subtract 2

    call   putgamma           ; output gamma coding of matchlen - 2

    dec    ecx                ; matchpos > 0, so subtract 1

    mov    eax, ecx           ; eax = (matchpos >> 8) + 2
    shr    eax, 8             ;
    add    eax, byte 2        ;

    call   putgamma           ; output gamma coding of (matchpos >> 8) + 2

    xchg   eax, ecx           ; output low 8 bits of matchpos
    stosb                     ;

    jmp    short .nexttag

  .donepacking:

    mov    eax, [esp + .lim$] ; ebx = source + length
    lea    ebx, [eax + 4]     ;

    jmp    short .check_final_literals

  .final_literals:
    clc
    call   putbit             ; 0-bit = literal

    movsb                     ; copy literal

  .check_final_literals:
    cmp    esi, ebx
    jb     short .final_literals

    test   ebp, ebp           ; do we need to fix the last tag?
    jz     short .EODdone     ;

  .doEOD:
    add    bp, bp             ; shift last tag into position
    jnc    short .doEOD       ;

    mov    [edx], bp          ; and put it into it's place

  .EODdone:
    mov    eax, edi           ; return packed length in eax
    sub    eax, [esp + .dst$] ;

    add    esp, byte 2*4

    pop    ebp
    pop    edi
    pop    esi
    pop    ebx

    lcmret 16

; =============================================================

putbit1:                      ; add 1-bit
    stc
putbit:                       ; add bit according to carry
    dec    ebp
    jns    short .bitsleft
    mov    edx, edi
    inc    edi
    inc    ebp
    inc    edi
  .bitsleft:
    inc    ebp
    adc    bp, bp
    jnc    short .done
    mov    [edx], bp
    xor    ebp, ebp
  .done:
    ret

putgamma:                     ; output gamma coding of value in eax
    push   ebx                ; (eax > 1)
    push   eax
    shr    eax, 1
    xor    ebx, ebx
    inc    ebx
  .revmore:
    shr    eax, 1
    jz     short .outstart
    adc    ebx, ebx
    jmp    short .revmore
  .outmore:
    call   putbit
    call   putbit1
  .outstart:
    shr    ebx, 1
    jnz    short .outmore
    pop    eax
    shr    eax, 1
    call   putbit
    call   putbit             ; CF = 0 from call above
    pop    ebx
    ret

hash4:                        ; hash next 4 bytes into eax
    push   ecx
    movzx  eax, byte [esi]
    imul   eax, 317
    movzx  ecx, byte [esi+1]
    add    eax, ecx
    imul   eax, 317
    mov    cl, [esi+2]
    add    eax, ecx
    imul   eax, 317
    mov    cl, [esi+3]
    add    eax, ecx
    and    eax, (BLZ_WORKMEM_SIZE/4)-1
    pop    ecx
    ret

; =============================================================

%ifdef _OBJ_
  section lcmdata
%endif

; =============================================================
