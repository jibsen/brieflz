/*
 * BriefLZ  -  small fast Lempel-Ziv
 *
 * C packer
 *
 * Copyright (c) 2002-2004 by Joergen Ibsen / Jibz
 * All Rights Reserved
 *
 * http://www.ibsensoftware.com/
 *
 * This software is provided 'as-is', without any express
 * or implied warranty.  In no event will the authors be
 * held liable for any damages arising from the use of
 * this software.
 *
 * Permission is granted to anyone to use this software
 * for any purpose, including commercial applications,
 * and to alter it and redistribute it freely, subject to
 * the following restrictions:
 *
 * 1. The origin of this software must not be
 *    misrepresented; you must not claim that you
 *    wrote the original software. If you use this
 *    software in a product, an acknowledgment in
 *    the product documentation would be appreciated
 *    but is not required.
 *
 * 2. Altered source versions must be plainly marked
 *    as such, and must not be misrepresented as
 *    being the original software.
 *
 * 3. This notice may not be removed or altered from
 *    any source distribution.
 */

#include "brieflz.h"

/* must be a power of 2 (between 8k and 2mb appear reasonable) */
#define BLZ_WORKMEM_SIZE (1024*1024)

#if BLZ_WORKMEM_SIZE & (BLZ_WORKMEM_SIZE-1)
# error BLZ_WORKMEM_SIZE must be a power of 2
#endif

/* internal data structure */
typedef struct {
   const unsigned char *source;
   unsigned char *destination;
   unsigned char *tagpos;
   unsigned int tag;
   unsigned int bitcount;
} BLZPACKDATA;

static void blz_putbit(BLZPACKDATA *ud, const int bit)
{
   /* check if tag is full */
   if (!ud->bitcount--)
   {
      /* store tag */
      ud->tagpos[0] = ud->tag & 0x00ff;
      ud->tagpos[1] = (ud->tag >> 8) & 0x00ff;

      /* init next tag */
      ud->tagpos = ud->destination;
      ud->destination += 2;
      ud->bitcount = 15;
   }

   /* shift bit into tag */
   ud->tag = (ud->tag << 1) + (bit ? 1 : 0);
}

static void blz_putgamma(BLZPACKDATA *ud, unsigned int val)
{
   unsigned int mask = val >> 1;

   /* mask = highest_bit(val >> 1) */
   while (mask & (mask - 1)) mask &= mask - 1;

   /* output gamma2-encoded bits */
   blz_putbit(ud, val & mask);

   while (mask >>= 1)
   {
      blz_putbit(ud, 1);
      blz_putbit(ud, val & mask);
   }

   blz_putbit(ud, 0);
}

static unsigned int blz_hash4(const unsigned char *data)
{
   /* hash next four bytes of data[] */
   unsigned int val = data[0];
   val = (val*317) + data[1];
   val = (val*317) + data[2];
   val = (val*317) + data[3];
   return (val & (BLZ_WORKMEM_SIZE/4 - 1));
}

unsigned int BLZCC blz_workmem_size(unsigned int length)
{
   /* return required workmem size */
   return BLZ_WORKMEM_SIZE;
}

unsigned int BLZCC blz_max_packed_size(unsigned int length)
{
   /* return max compressed size */
   return length + length/8 + 64;
}

unsigned int BLZCC blz_pack(const void *source,
                            void *destination,
                            unsigned int length,
                            void *workmem)
{
   BLZPACKDATA ud;
   const unsigned char **lookup = workmem;
   const unsigned char *backptr = source;

   /* check for length == 0 */
   if (length == 0) return 0;

   /* init lookup[] */
   {
      int i;
      for (i = 0; i < BLZ_WORKMEM_SIZE/4; ++i) lookup[i] = 0;
   }

   ud.source = source;
   ud.destination = destination;

   /* first byte verbatim */
   *ud.destination++ = *ud.source++;

   /* check for length == 1 */
   if (--length == 0) return 1;

   /* init first tag */
   ud.tagpos = ud.destination;
   ud.destination += 2;
   ud.tag = 0;
   ud.bitcount = 16;

   /* main compression loop */
   while (length > 4)
   {
      const unsigned char *ppos;
      unsigned int len = 0;

      /* update lookup[] up to current position */
      while (backptr < ud.source)
      {
	 lookup[blz_hash4(backptr)] = backptr;
	 backptr++;
      }

      /* look up current position */
      ppos = lookup[blz_hash4(ud.source)];

      /* check match */
      if (ppos)
      {
	 while ((len < length) &&
		(*(ppos + len) == *(ud.source + len))) ++len;
      }

      /* output match or literal */
      if (len > 3)
      {
	 unsigned int pos = ud.source - ppos - 1;

	 /* output match tag */
	 blz_putbit(&ud, 1);

	 /* output length */
	 blz_putgamma(&ud, len - 2);

	 /* output position */
	 blz_putgamma(&ud, (pos >> 8) + 2);
	 *ud.destination++ = pos & 0x00ff;

	 ud.source += len;
	 length -= len;

      } else {

	 /* output literal tag */
	 blz_putbit(&ud, 0);

	 /* copy literal */
	 *ud.destination++ = *ud.source++;
	 length--;
      }
   }

   /* output any remaining literals */
   while (length > 0)
   {
      /* output literal tag */
      blz_putbit(&ud, 0);

      /* copy literal */
      *ud.destination++ = *ud.source++;
      length--;
   }

   /* shift last tag into position and store */
   ud.tag <<= ud.bitcount;
   ud.tagpos[0] = ud.tag & 0x00ff;
   ud.tagpos[1] = (ud.tag >> 8) & 0x00ff;

   /* return compressed length */
   return ud.destination - (unsigned char *)destination;
}
