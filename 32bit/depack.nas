;;
;; BriefLZ  -  small fast Lempel-Ziv
;;
;; NASM assembler depacker
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

cpu 386

bits 32

%include "nasmlcm.inc"

section lcmtext

lcmglobal blz_depack_asm,12

lcmexport blz_depack_asm,12

; =============================================================

%macro getbitM 0              ; get next tag-bit into carry
    add    dx, dx
    jnz    short %%stillbitsleft
    mov    dx, [esi]
    lea    esi, [esi + 2]
    adc    dx, dx
  %%stillbitsleft:
%endmacro

%macro domatchM 1             ; copy a match, ecx = len, param = pos
    push   esi
    mov    esi, edi
    sub    esi, %1
    rep    movsb
    pop    esi
%endmacro

%macro getgammaM 1            ; gamma decode value into param
    mov    %1, 1
  %%getmore:
    getbitM
    adc    %1, %1
    getbitM
    jc     short %%getmore
%endmacro

; =============================================================

lcmlabel blz_depack_asm,12
    ; blz_depack_asm(const void *source,
    ;                void *destination,
    ;                unsigned int length);

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
    mov    dx, 8000h          ; initialise tag

    add    ebx, edi           ; ebx = destination + length

  .literal:
    mov    al, [esi]          ; copy literal
    inc    esi                ;
    mov    [edi], al          ;
    inc    edi                ;

    cmp    edi, ebx           ; are we done?
    jae    near .donedepacking

  .nexttag:
    getbitM                   ; literal or match?
    jnc    short .literal     ;

    getgammaM ecx             ; ecx = matchlen

    getgammaM eax             ; eax = (matchpos >> 8) + 2

    add    ecx, byte 2        ; matchlen >= 4, so add 2

    shl    eax, 8             ; eax = high part of matchpos
    mov    al, [esi]          ; add low 8 bits of matchpos
    inc    esi                ;

    add    eax, 0xfffffe01    ; adjust matchpos (highpart-=2, lowpart+=1)

    domatchM eax              ; copy match

    cmp    edi, ebx           ; are we done?
    jb     near .nexttag

  .donedepacking:
    mov    eax, edi           ; return unpacked length in eax
    sub    eax, [esp + .dst$] ;

    pop    edi
    pop    esi
    pop    ebx

    lcmret 12

; =============================================================

%ifdef _OBJ_
  section lcmdata
%endif

; =============================================================
