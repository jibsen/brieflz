/*
 * BriefLZ  -  small fast Lempel-Ziv
 *
 * assembler packer, header file
 *
 * Copyright (c) 2002-2003 by Joergen Ibsen / Jibz
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

unsigned int BLZCC blz_workmem_size(unsigned int length);

unsigned int BLZCC blz_max_packed_size(unsigned int length);

unsigned int BLZCC blz_pack_asm(const void *source,
                                void *destination,
                                unsigned int length,
                                void *workmem);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* BRIEFLZ_H_INCLUDED */
