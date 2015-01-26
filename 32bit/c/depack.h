/*
 * BriefLZ  -  small fast Lempel-Ziv
 *
 * C depacker, header file
 *
 * Copyright (c) 2002-2004 by Joergen Ibsen / Jibz
 * All Rights Reserved
 *
 * http://www.ibsensoftware.com/
 */

#ifndef DEPACK_H_INCLUDED
#define DEPACK_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

/* function prototypes */

unsigned int blz_depack(const void *source,
                        void *destination,
                        unsigned int depacked_length);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* DEPACK_H_INCLUDED */
