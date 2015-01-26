;;
;; BriefLZ  -  small fast Lempel-Ziv
;;
;; NASM 16-bit assembler crc32
;;
;; Copyright (c) 1998-2015 by Joergen Ibsen / Jibz
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

global _blz_crc32

; =============================================================

_blz_crc32:
    ; blz_crc32(const void far *source,
    ;           unsigned short length,
    ;           unsigned long initial_crc32);

    .crc$  equ 4*2 + 2 + 6
    .len$  equ 4*2 + 2 + 4
    .src$  equ 4*2 + 2

    push   bx
    push   si
    push   ds
    push   bp

    mov    bp, sp

    lds    si, [bp + .src$]   ; ds:si -> buffer
    mov    cx, [bp + .len$]   ; cx = length

    mov    ax, [bp + .crc$]     ; dx:ax = initial_crc32
    mov    dx, [bp + .crc$ + 2] ;

    jcxz   .c_exit

    not    dx                 ; crc ^= 0xffffffff
    not    ax                 ;

  .c_next_byte:
    xor    al, [si]
    inc    si

    mov    bp, 2

  .c_next_nibble:
    mov    bx, 0x0f           ;
    and    bx, ax             ; bx = low nibble

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

    xor    ax, [cs:bx + blz_crctab_n]     ; crc ^= crctab[low nibble]
    xor    dx, [cs:bx + blz_crctab_n + 2] ;

    dec    bp
    jnz    short .c_next_nibble

    dec    cx
    jnz    short .c_next_byte

    not    dx                 ; crc ^= 0xffffffff
    not    ax                 ;

  .c_exit:
    pop    bp
    pop    ds
    pop    si
    pop    bx

    ret

align 4

blz_crctab_n dd 0x00000000, 0x1db71064, 0x3b6e20c8, 0x26d930ac, 0x76dc4190
             dd 0x6b6b51f4, 0x4db26158, 0x5005713c, 0xedb88320, 0xf00f9344
             dd 0xd6d6a3e8, 0xcb61b38c, 0x9b64c2b0, 0x86d3d2d4, 0xa00ae278
             dd 0xbdbdf21c

; =============================================================

section _DATA class=DATA public use16 align=4

; =============================================================
