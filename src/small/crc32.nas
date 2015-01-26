;;
;; BriefLZ  -  small fast Lempel-Ziv
;;
;; NASM small assembler crc32
;;
;; Copyright (c) 1998-2004 by Joergen Ibsen / Jibz
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

; CRC32 algorithm taken from the zlib source, which is
; Copyright (C) 1995-1998 Jean-loup Gailly and Mark Adler

cpu 386

bits 32

%include "nasmlcm.inc"

section lcmtext

lcmglobal blz_crc32,12

lcmexport blz_crc32,12

; =============================================================

lcmlabel blz_crc32,12
    ; blz_crc32(const void *source,
    ;           unsigned int length,
    ;           unsigned int initial_crc32);

    .crc$  equ 1*4 + 4 + 8
    .len$  equ 1*4 + 4 + 4
    .src$  equ 1*4 + 4

    push   esi

    mov    esi, [esp + .src$] ; esi -> buffer
    mov    ecx, [esp + .len$] ; ecx =  length
    mov    eax, [esp + .crc$] ; crc =  initial_crc32

    test   esi, esi
    jz     short .c_exit

    jecxz  .c_exit

    not    eax                ; crc ^= 0xffffffff

    sub    edx, edx

  .c_next_byte:
    xor    al, [esi]
    inc    esi

    mov    dl, 8
  .c_xor_loop:
    shr    eax, 1
    jnc    short .c_xor_done
    xor    eax, 0xedb88320
  .c_xor_done:
    dec    edx
    jnz    short .c_xor_loop

    dec    ecx
    jnz    short .c_next_byte

    not    eax                ; crc ^= 0xffffffff

  .c_exit:
    pop    esi

    lcmret 12

; =============================================================

%ifdef LCM_OBJ
  section lcmdata
%endif

; =============================================================
