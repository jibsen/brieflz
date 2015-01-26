/*
 * BriefLZ  -  small fast Lempel-Ziv
 *
 * C packer, header file
 *
 * Copyright (c) 2002-2004 by Joergen Ibsen / Jibz
 * All Rights Reserved
 *
 * http://www.ibsensoftware.com/
 */

#ifndef BRIEFLZ_H_INCLUDED
#define BRIEFLZ_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

/* function prototypes */

unsigned int blz_workmem_size(unsigned int length);

unsigned int blz_max_packed_size(unsigned int length);

unsigned int blz_pack(const void *source,
                      void *destination,
                      unsigned int length,
                      void *workmem);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* BRIEFLZ_H_INCLUDED */
