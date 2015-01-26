;;
;; BriefLZ  -  small fast Lempel-Ziv
;;
;; NASM 16-bit assembler depacker
;;
;; Copyright (c) 2002-2004 by Joergen Ibsen / Jibz
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

cpu 8086

bits 16

section _TEXT class=CODE public use16 align=4

group DGROUP _DATA

global _blz16_depack_asm

; =============================================================

_blz16_depack_asm:
    ; blz16_depack_asm_small(const void far *source,
    ;                        void far *destination,
    ;                        unsigned short depacked_length);

    .len$  equ 6*2 + 2 + 8
    .dst$  equ 6*2 + 2 + 4
    .src$  equ 6*2 + 2

    push   bx
    push   si
    push   di
    push   ds
    push   es
    push   bp

    mov    bp, sp

    lds    si, [bp + .src$]   ; ds:si -> source[]
    les    di, [bp + .dst$]   ; es:di -> destination[]
    mov    bx, [bp + .len$]   ; bx = length

    cld
    xor    dx, dx             ; initialise tag

    add    bx, di             ; bx = destination + length

  .literal:
    movsb                     ; copy literal

  .nexttag:
    cmp    di, bx             ; are we done?
    jae    short .donedepacking

    call   .getbit            ; literal or match?
    jnc    short .literal     ;

    call   .getgamma          ; cx = matchlen
    xchg   ax, cx             ;

    call   .getgamma          ; ax = (matchpos >> 8) + 2

    dec    ax                 ; ax = (matchpos >> 8)
    dec    ax                 ;

    inc    cx                 ; matchlen >= 4, so add 2
    inc    cx                 ;

    mov    ah, al             ; ah = high part of matchpos
    lodsb                     ; add low 8 bits of matchpos

    inc    ax                 ; matchpos > 0, so add 1

    push   si

    mov    si, di             ; copy match
    sub    si, ax             ;
    rep    es movsb           ;

    pop    si

    jmp    short .nexttag

  .getbit:                    ; get next tag-bit into carry
    add    dx, dx
    jnz    short .stillbitsleft
    xchg   ax, dx
    lodsw
    xchg   ax, dx
    add    dx, dx
    inc    dx
  .stillbitsleft:
    ret

  .getgamma:                  ; gamma decode value into ax
    mov    ax, 1
  .getmore:
    call   .getbit
    adc    ax, ax
    call   .getbit
    jc     short .getmore
    ret

  .donedepacking:
    mov    ax, di             ; return unpacked length in ax
    sub    ax, [bp + .dst$]   ;

    pop    bp
    pop    es
    pop    ds
    pop    di
    pop    si
    pop    bx

    ret

; =============================================================

section _DATA class=DATA public use16 align=4

; =============================================================
