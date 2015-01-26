;;
;; BriefLZ  -  small fast Lempel-Ziv
;;
;; NASM small assembler depacker
;;
;; Copyright (c) 2002-2015 by Joergen Ibsen / Jibz
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

cpu 386

bits 32

%include "nasmlcm.inc"

section lcmtext

lcmglobal blz_depack,12

lcmexport blz_depack,12

; =============================================================

lcmlabel blz_depack,12
    ; blz_depack(const void *source,
    ;            void *destination,
    ;            unsigned int depacked_length);

    .len$  equ 3*4 + 4 + 8
    .dst$  equ 3*4 + 4 + 4
    .src$  equ 3*4 + 4

    push   ebx
    push   esi
    push   edi

    mov    esi, [esp + .src$]
    mov    edi, [esp + .dst$]
    mov    ebx, [esp + .len$]

    cld
    xor    edx, edx           ; initialise tag

    add    ebx, edi           ; ebx = destination + length

  .literal:
    movsb                     ; copy literal

  .nexttag:
    cmp    edi, ebx           ; are we done?
    jae    short .donedepacking

    call   .getbit            ; literal or match?
    jnc    short .literal     ;

    call   .getgamma          ; ecx = matchlen
    xchg   eax, ecx           ;

    call   .getgamma          ; eax = (matchpos >> 8) + 2

    dec    eax                ; eax = (matchpos >> 8)
    dec    eax                ;

    inc    ecx                ; matchlen >= 4, so add 2
    inc    ecx                ;

    shl    eax, 8             ; eax = high part of matchpos
    lodsb                     ; add low 8 bits of matchpos

    inc    eax                ; matchpos > 0, so add 1

    push   esi

    mov    esi, edi           ; copy match
    sub    esi, eax           ;
    rep    movsb              ;

    pop    esi

    jmp    short .nexttag

  .getbit:                    ; get next tag-bit into carry
    add    dx, dx
    jnz    short .stillbitsleft
    xchg   eax, edx
    lodsw
    xchg   eax, edx
    add    dx, dx
    inc    edx
  .stillbitsleft:
    ret

  .getgamma:                  ; gamma decode value into eax
    xor    eax, eax
    inc    eax
  .getmore:
    call   .getbit
    adc    eax, eax
    call   .getbit
    jc     short .getmore
    ret

  .donedepacking:
    xchg   eax, edi           ; return unpacked length in eax
    sub    eax, [esp + .dst$] ;

    pop    edi
    pop    esi
    pop    ebx

    lcmret 12

; =============================================================

%ifdef LCM_OBJ
  section lcmdata
%endif

; =============================================================
