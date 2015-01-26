/*
 * BriefLZ  -  small fast Lempel-Ziv
 *
 * 16-bit assembler packer, header file
 *
 * Copyright (c) 2002-2004 by Joergen Ibsen / Jibz
 * All Rights Reserved
 *
 * http://www.ibsensoftware.com/
 */

#ifndef BRIEFLZ_H_INCLUDED
#define BRIEFLZ_H_INCLUDED

/* calling convention */
#ifndef BLZCC
 #ifdef __WATCOMC__
  #define BLZCC __cdecl
 #else
  #define BLZCC
 #endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* function prototypes */

unsigned short BLZCC blz16_workmem_size(unsigned short length);

unsigned short BLZCC blz16_max_packed_size(unsigned short length);

unsigned short BLZCC blz16_pack_asm(const void far *source,
                                    void far *destination,
                                    unsigned short length,
                                    void far *workmem);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* BRIEFLZ_H_INCLUDED */
