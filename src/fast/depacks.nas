;;
;; BriefLZ  -  small fast Lempel-Ziv
;;
;; NASM safe assembler depacker
;;
;; Copyright (c) 2002-2005 by Joergen Ibsen / Jibz
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

lcmglobal blz_depack_safe,16

lcmexport blz_depack_safe,16

; =============================================================

%macro getbitM 0              ; get next tag-bit into carry
    add    dx, dx
    jnz    short %%stillbitsleft

    sub    ebp, byte 2        ; read two bytes from source
    jc     .return_error      ;

    mov    dx, [esi]
    add    esi, byte 2

    add    dx, dx
    inc    dx
  %%stillbitsleft:
%endmacro

%macro domatchM 1             ; copy a match, ecx = len, param = pos
    push   ecx
    mov    ecx, [esp + 4 + .dlen$] ; ecx = dstlen
    sub    ecx, ebx                ; ecx = num written
    cmp    %1, ecx
    pop    ecx
    ja     .return_error

    sub    ebx, ecx           ; write ecx bytes to destination
    jc     .return_error      ;

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
    jc     .return_error
    getbitM
    jc     short %%getmore
%endmacro

; =============================================================

lcmlabel blz_depack_safe,16
    ; blz_depack_safe(const void *source,
    ;                 unsigned int srclen,
    ;                 void *destination,
    ;                 unsigned int depacked_length);

    .dlen$ equ 4*4 + 4 + 12
    .dst$  equ 4*4 + 4 + 8
    .slen$ equ 4*4 + 4 + 4
    .src$  equ 4*4 + 4

    push   ebx
    push   ebp
    push   esi
    push   edi

    mov    esi, [esp + .src$]
    mov    ebp, [esp + .slen$]
    mov    edi, [esp + .dst$]
    mov    ebx, [esp + .dlen$]

    cld
    mov    dx, 8000h          ; initialise tag

  .literal:
    sub    ebp, byte 1        ; read one byte from source
    jc     .return_error      ;

    mov    al, [esi]          ; read literal
    inc    esi                ;

    sub    ebx, byte 1        ; write one byte to destination
    jc     .return_error      ;

    mov    [edi], al          ; write literal
    inc    edi                ;

    test   ebx, ebx           ; are we done?
    jz     .donedepacking

  .nexttag:
    getbitM                   ; literal or match?
    jnc    short .literal     ;

    getgammaM ecx             ; ecx = matchlen

    getgammaM eax             ; eax = (matchpos >> 8) + 2

    add    ecx, byte 2        ; matchlen >= 4, so add 2

    shl    eax, 8             ; eax = high part of matchpos

    sub    ebp, byte 1        ; read one byte from source
    jc     .return_error      ;

    mov    al, [esi]          ; add low 8 bits of matchpos
    inc    esi                ;

    add    eax, 0xfffffe01    ; adjust matchpos (highpart-=2, lowpart+=1)

    domatchM eax              ; copy match

    test   ebx, ebx           ; are we done?
    jnz    .nexttag

  .donedepacking:
    mov    eax, edi           ; return unpacked length in eax
    sub    eax, [esp + .dst$] ;

    jmp    .return_eax

  .return_error:
    or     eax, byte -1

  .return_eax:
    pop    edi
    pop    esi
    pop    ebp
    pop    ebx

    lcmret 16

; =============================================================

%ifdef LCM_OBJ
  section lcmdata
%endif

; =============================================================
