;;
;; NASM 16-bit assembler crc32
;;
;; Copyright (c) 1998-2003 by Joergen Ibsen / Jibz
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

cpu 8086

bits 16

section _TEXT class=CODE public use16 align=4

group DGROUP _DATA

global _is16_crc32_asm

; =============================================================

_is16_crc32_asm:
    ; is16_crc32_asm(const void far *source,
    ;                unsigned short length);

    .len$  equ 6*2 + 2 + 4
    .src$  equ 6*2 + 2

    push   bx
    push   si
    push   di
    push   ds
    push   es
    push   bp

    mov    bp, sp

    lds    si, [bp + .src$]   ; ds:si -> buffer
    mov    cx, [bp + .len$]   ; cx = length

    mov    ax, seg is16_crctab_n ; es:di -> crctab
    mov    es, ax                ;
    mov    di, is16_crctab_n     ;

    mov    ax, -1             ; ds:ax = crc = 0xffffffff
    cwd                       ;

    jcxz   .c_done

  .c_next_byte:
    xor    al, [si]
    inc    si

    mov    bp, 2

  .c_next_nibble:
    mov    bx, ax             ; bx = low nibble
    and    bx, byte 0x0f      ;

    shr    dx, 1              ; crc >>= 4
    rcr    ax, 1              ;
    shr    dx, 1              ;
    rcr    ax, 1              ;
    shr    dx, 1              ;
    rcr    ax, 1              ;
    shr    dx, 1              ;
    rcr    ax, 1              ;

    shl    bx, 1
    shl    bx, 1

    add    bx, di

    xor    ax, [es:bx]        ; crc ^= crctab[low nibble]
    xor    dx, [es:bx + 2]    ;

    dec    bp
    jnz    short .c_next_nibble

    dec    cx
    jnz    short .c_next_byte

  .c_done:
    not    dx
    not    ax

    pop    bp
    pop    es
    pop    ds
    pop    di
    pop    si
    pop    bx

    ret

; =============================================================

section _DATA class=DATA public use16 align=4

is16_crctab_n dd 0x00000000, 0x1db71064, 0x3b6e20c8, 0x26d930ac, 0x76dc4190
              dd 0x6b6b51f4, 0x4db26158, 0x5005713c, 0xedb88320, 0xf00f9344
              dd 0xd6d6a3e8, 0xcb61b38c, 0x9b64c2b0, 0x86d3d2d4, 0xa00ae278
              dd 0xbdbdf21c

; =============================================================
