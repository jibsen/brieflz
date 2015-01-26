/*
 * BriefLZ  -  small fast Lempel-Ziv
 *
 * 16-bit C/C++ header file
 *
 * Copyright (c) 2002-2005 by Joergen Ibsen / Jibz
 * All Rights Reserved
 *
 * http://www.ibsensoftware.com/
 */

#ifndef BRIEFLZ_H_INCLUDED
#define BRIEFLZ_H_INCLUDED

/* calling convention */
#ifndef BLZCC
# if defined __WATCOMC__
#  define BLZCC __cdecl
# elif defined __TURBOC__
#  define BLZCC cdecl
# else
#  define BLZCC
# endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Compress data.
 * @param source - pointer to data.
 * @param destination - where to store the compressed data.
 * @param length - the length in bytes of the data.
 * @param workmem - pointer to memory for temporary use.
 * @return the length of the compressed data.
 */
unsigned short BLZCC blz_pack(const void far *source,
                              void far *destination,
                              unsigned short length,
                              void far *workmem);


/**
 * Decompress data.
 * @param source - pointer to the compressed data.
 * @param destination - where to store the decompressed data.
 * @param depacked_length - the length of the decompressed data.
 * @return the length of the decompressed data.
 */
unsigned short BLZCC blz_depack(const void far *source,
                                void far *destination,
                                unsigned short depacked_length);


/**
 * Get the required size of the workmem buffer.
 * @param length - the length in bytes of the data.
 * @return required size in bytes of the workmem buffer.
 */
unsigned short BLZCC blz_workmem_size(unsigned short length);


/**
 * Get the maximum output size produced on uncompressible data.
 * @param length - the length in bytes of the data.
 * @return maximum required size in bytes of the output buffer.
 */
unsigned short BLZCC blz_max_packed_size(unsigned short length);


/**
 * Compute the CRC32 of a buffer.
 * @param source - pointer to the data.
 * @param length - the number of bytes to process.
 * @param initial_crc32 - the current CRC32 value (pass 0 for first block).
 * @return the CRC32 of the data.
 */
unsigned long BLZCC blz_crc32(const void far *source,
                              unsigned short length,
                              unsigned long initial_crc32);


#if defined __WATCOMC__ && !defined __386__
# pragma aux (cdecl) blz_pack            modify exact [ax cx dx]
# pragma aux (cdecl) blz_depack          modify exact [ax cx dx]
# pragma aux (cdecl) blz_workmem_size    modify exact [ax]
# pragma aux (cdecl) blz_max_packed_size modify exact [ax dx]
# pragma aux (cdecl) blz_crc32           modify exact [ax cx dx]
#endif

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* BRIEFLZ_H_INCLUDED */
