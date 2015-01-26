/*
 * BriefLZ  -  small fast Lempel-Ziv
 *
 * C depacker
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

/* internal data structure */
typedef struct {
   const unsigned char *source;
   unsigned char *destination;
   unsigned int tag;
   unsigned int bitcount;
} BLZDEPACKDATA;

static int blz_getbit(BLZDEPACKDATA *ud)
{
   unsigned int bit;

   /* check if tag is empty */
   if (!ud->bitcount--)
   {
      /* load next tag */
      ud->tag = ud->source[0] + ((unsigned int)ud->source[1] << 8);
      ud->source += 2;
      ud->bitcount = 15;
   }

   /* shift bit out of tag */
   bit = (ud->tag >> 15) & 0x01;
   ud->tag <<= 1;

   return bit;
}

static unsigned int blz_getgamma(BLZDEPACKDATA *ud)
{
   unsigned int result = 1;

   /* input gamma2-encoded bits */
   do {
      result = (result << 1) + blz_getbit(ud);
   } while (blz_getbit(ud));

   return (result);
}

unsigned int BLZCC blz_depack(const void *source,
                              void *destination,
                              unsigned int depacked_length)
{
   BLZDEPACKDATA ud;
   unsigned int length = 1;

   /* check for length == 0 */
   if (depacked_length == 0) return 0;

   ud.source = source;
   ud.destination = destination;
   ud.bitcount = 0;

   /* first byte verbatim */
   *ud.destination++ = *ud.source++;

   /* main decompression loop */
   while (length < depacked_length)
   {
      if (blz_getbit(&ud))
      {
	 /* input match length and position */
	 unsigned int len = blz_getgamma(&ud) + 2;
	 unsigned int pos = blz_getgamma(&ud) - 2;

	 pos = (pos << 8) + *ud.source++ + 1;

	 /* copy match */
	 {
	    const unsigned char *ppos = ud.destination - pos;
	    int i;
	    for (i = len; i > 0; --i) *ud.destination++ = *ppos++;
	 }

	 length += len;

      } else {

	 /* copy literal */
	 *ud.destination++ = *ud.source++;

	 length++;
      }
   }

   /* return decompressed length */
   return length;
}
