/*
 * BriefLZ - small fast Lempel-Ziv
 *
 * C depacker
 *
 * Copyright (c) 2002-2015 Joergen Ibsen
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 *   1. The origin of this software must not be misrepresented; you must
 *      not claim that you wrote the original software. If you use this
 *      software in a product, an acknowledgment in the product
 *      documentation would be appreciated but is not required.
 *
 *   2. Altered source versions must be plainly marked as such, and must
 *      not be misrepresented as being the original software.
 *
 *   3. This notice may not be removed or altered from any source
 *      distribution.
 */

#include "brieflz.h"

/* internal data structure */
struct blz_state {
	const unsigned char *src;
	unsigned char *dst;
	unsigned int tag;
	unsigned int bitcount;
};

static unsigned int
blz_getbit(struct blz_state *bs)
{
	unsigned int bit;

	/* check if tag is empty */
	if (!bs->bitcount--) {
		/* load next tag */
		bs->tag = (unsigned int) bs->src[0]
		       | ((unsigned int) bs->src[1] << 8);
		bs->src += 2;
		bs->bitcount = 15;
	}

	/* shift bit out of tag */
	bit = (bs->tag >> 15) & 0x01;
	bs->tag <<= 1;

	return bit;
}

static unsigned int
blz_getgamma(struct blz_state *bs)
{
	unsigned int result = 1;

	/* input gamma2-encoded bits */
	do {
		result = (result << 1) + blz_getbit(bs);
	} while (blz_getbit(bs));

	return result;
}

unsigned int
blz_depack(const void *src, void *dst, unsigned int depacked_size)
{
	struct blz_state bs;
	unsigned int dst_size = 1;

	/* check for length == 0 */
	if (depacked_size == 0) {
		return 0;
	}

	bs.src = (const unsigned char *) src;
	bs.dst = (unsigned char *) dst;
	bs.bitcount = 0;

	/* first byte verbatim */
	*bs.dst++ = *bs.src++;

	/* main decompression loop */
	while (dst_size < depacked_size) {
		if (blz_getbit(&bs)) {
			/* input match length and offset */
			unsigned int len = blz_getgamma(&bs) + 2;
			unsigned int off = blz_getgamma(&bs) - 2;

			off = (off << 8) + (unsigned int) *bs.src++ + 1;

			/* copy match */
			{
				const unsigned char *p = bs.dst - off;
				int i;
				for (i = len; i > 0; --i) {
					*bs.dst++ = *p++;
				}
			}

			dst_size += len;
		}
		else {
			/* copy literal */
			*bs.dst++ = *bs.src++;

			dst_size++;
		}
	}

	/* return decompressed size */
	return dst_size;
}
