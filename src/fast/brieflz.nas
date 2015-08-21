;;
;; BriefLZ - small fast Lempel-Ziv
;;
;; NASM assembler packer
;;
;; Copyright (c) 2002-2015 Joergen Ibsen
;;
;; This software is provided 'as-is', without any express or implied
;; warranty. In no event will the authors be held liable for any damages
;; arising from the use of this software.
;;
;; Permission is granted to anyone to use this software for any purpose,
;; including commercial applications, and to alter it and redistribute it
;; freely, subject to the following restrictions:
;;
;;   1. The origin of this software must not be misrepresented; you must
;;      not claim that you wrote the original software. If you use this
;;      software in a product, an acknowledgment in the product
;;      documentation would be appreciated but is not required.
;;
;;   2. Altered source versions must be plainly marked as such, and must
;;      not be misrepresented as being the original software.
;;
;;   3. This notice may not be removed or altered from any source
;;      distribution.
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
lcmglobal blz_pack,16

lcmexport blz_workmem_size,4
lcmexport blz_max_packed_size,4
lcmexport blz_pack,16

; =============================================================

%macro putbit0M 0             ; add a 0-bit to the current tag word
    test   ebp, ebp
    jnz    short %%bitsleft
    mov    edx, edi
    inc    ebp
    add    edi, byte 2
  %%bitsleft:
    add    bp, bp
    jnc    short %%done
    mov    [edx], bp
    xor    ebp, ebp
  %%done:
%endmacro

%macro putbit1M 0             ; add a 1-bit to the current tag word
    test   ebp, ebp
    jnz    short %%bitsleft
    mov    edx, edi
    inc    ebp
    add    edi, byte 2
  %%bitsleft:
    add    bp, bp
    inc    bp
    jnc    short %%done
    mov    [edx], bp
    xor    ebp, ebp
  %%done:
%endmacro

%macro putbitM 0              ; add bit according to carry
    jc     short %%onebit
    putbit0M
    jmp    short %%bitdone
  %%onebit:
    putbit1M
  %%bitdone:
%endmacro

%macro putgammaM 0            ; output gamma coding of value in eax
    push   ebx                ; (eax > 1)
    push   eax
    shr    eax, 1
    mov    ebx, 1
  %%revmore:
    shr    eax, 1
    jz     short %%outstart
    adc    ebx, ebx
    jmp    short %%revmore
  %%outmore:
    putbitM
    putbit1M
  %%outstart:
    shr    ebx, 1
    jnz    short %%outmore
    pop    eax
    shr    eax, 1
    putbitM
    putbit0M
    pop    ebx
%endmacro

%macro hash4M 0               ; hash next 4 bytes into eax
    push   ecx
    movzx  eax, byte [esi]
    imul   eax, 317           ; the imuls can be replaced with:
    movzx  ecx, byte [esi+1]  ;
    add    eax, ecx           ;   lea    ecx, [eax*2 + eax]
    imul   eax, 317           ;   shl    eax, 6
    movzx  ecx, byte [esi+2]  ;   lea    eax, [eax*4 + eax]
    add    eax, ecx           ;   sub    eax, ecx
    imul   eax, 317
    movzx  ecx, byte [esi+3]
    add    eax, ecx
    and    eax, (BLZ_WORKMEM_SIZE/4)-1
    pop    ecx
%endmacro

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

lcmlabel blz_pack,16
    ; blz_pack(const void *source,
    ;          void *destination,
    ;          unsigned int length,
    ;          void *workmem);

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
    jz     near .EODdone      ;

    mov    al, [esi]          ; fist byte verbatim
    inc    esi                ;
    mov    [edi], al          ;
    inc    edi                ;

    cmp    ebx, byte 1        ; only one byte?
    je     near .EODdone      ;

    mov    bp, 1              ; initialise tag
    mov    edx, edi           ;
    add    edi, byte 2        ;

    jmp    short .nexttagcheck

  .no_match:
    putbit0M                  ; 0-bit = literal

    mov    al, [esi]          ; copy literal
    inc    esi                ;
    mov    [edi], al          ;
    inc    edi                ;

  .nexttagcheck:
    cmp    esi, [esp + .lim$] ; are we done?
    jae    near .donepacking  ;

  .nexttag:
    mov    ecx, [esp + .wkm$] ; ecx -> lookuptable[]

    mov    ebx, esi           ; ebx = buffer - backptr
    mov    esi, [esp + .bpt$] ; i.e. distance from backptr to current
    sub    ebx, esi           ;

  .update:
    hash4M                    ; hash next 4 bytes

    mov    [ecx + eax*4], esi ; lookuptable[hash] = backptr

    inc    esi                ; ++backptr
    dec    ebx
    jnz    short .update

    mov    [esp + .bpt$], esi ; esi is now back to current pos

    hash4M                    ; hash next 4 bytes

    mov    ebx, [ecx + eax*4] ; ebx = lookuptable[hash]

    test   ebx, ebx           ; no match?
    jz     near .no_match     ;

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
    jb     near .no_match     ;

    mov    ecx, esi           ;
    sub    ecx, ebx           ; ecx = matchpos

    putbit1M                  ; 1-bit = match

    add    esi, eax           ; update esi to next position

    sub    eax, byte 2        ; matchlen >= 4, so subtract 2

    putgammaM                 ; output gamma coding of matchlen - 2

    dec    ecx                ; matchpos > 0, so subtract 1

    mov    eax, ecx           ; eax = (matchpos >> 8) + 2
    shr    eax, 8             ;
    add    eax, byte 2        ;

    putgammaM                 ; output gamma coding of (matchpos >> 8) + 2

    mov    [edi], cl          ; output low 8 bits of matchpos
    inc    edi                ;

    cmp    esi, [esp + .lim$] ; are we done?
    jb     near .nexttag      ;

  .donepacking:
    mov    ebx, [esp + .lim$] ; ebx = source + length
    add    ebx, byte 4        ;

    jmp    short .check_final_literals

  .final_literals:
    putbit0M                  ; 0-bit = literal

    mov    al, [esi]          ; copy literal
    inc    esi                ;
    mov    [edi], al          ;
    inc    edi                ;

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

%ifdef LCM_OBJ
  section lcmdata
%endif

; =============================================================
