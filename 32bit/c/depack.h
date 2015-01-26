/*
 * BriefLZ  -  small fast Lempel-Ziv
 *
 * C depacker, header file
 *
 * Copyright (c) 2002-2003 by Joergen Ibsen / Jibz
 * All Rights Reserved
 *
 * http://www.ibsensoftware.com/
 */

#ifndef __DEPACK_H_INCLUDED
#define __DEPACK_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

/* function prototypes */

unsigned int blz_depack(const void *source,
                        void *destination,
                        unsigned int length);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* __DEPACK_H_INCLUDED */
