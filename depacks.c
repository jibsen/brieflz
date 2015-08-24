/*
 * BriefLZ - small fast Lempel-Ziv
 *
 * C safe depacker
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
	const unsigned char *source;
	unsigned char *destination;
	unsigned int srclen;
	unsigned int dstlen;
	unsigned int tag;
	unsigned int bitcount;
};

static int
blz_getbit_safe(struct blz_state *bs, unsigned int *result)
{
	unsigned int bit;

	/* check if tag is empty */
	if (!bs->bitcount--) {
		if (bs->srclen < 2) {
			return 0;
		}
		bs->srclen -= 2;

		/* load next tag */
		bs->tag = bs->source[0] + ((unsigned int) bs->source[1] << 8);
		bs->source += 2;
		bs->bitcount = 15;
	}

	/* shift bit out of tag */
	bit = (bs->tag >> 15) & 0x01;
	bs->tag <<= 1;

	*result = bit;

	return 1;
}

static int
blz_getgamma_safe(struct blz_state *bs, unsigned int *result)
{
	unsigned int bit;
	unsigned int v = 1;

	/* input gamma2-encoded bits */
	do {
		if (!blz_getbit_safe(bs, &bit)) {
			return 0;
		}

		v = (v << 1) + bit;

		if (!blz_getbit_safe(bs, &bit)) {
			return 0;
		}
	} while (bit);

	*result = v;

	return 1;
}

unsigned int
blz_depack_safe(const void *source, unsigned int srclen,
                void *destination, unsigned int depacked_length)
{
	struct blz_state bs;
	unsigned int length = 1;
	unsigned int bit;

	/* check for length == 0 */
	if (depacked_length == 0) {
		return 0;
	}

	bs.source = (const unsigned char *) source;
	bs.srclen = srclen;
	bs.destination = (unsigned char *) destination;
	bs.dstlen = depacked_length;
	bs.bitcount = 0;

	/* first byte verbatim */
	if (!bs.srclen-- || !bs.dstlen--) {
		return BLZ_ERROR;
	}
	*bs.destination++ = *bs.source++;

	/* main decompression loop */
	while (length < depacked_length) {
		if (!blz_getbit_safe(&bs, &bit)) {
			return BLZ_ERROR;
		}

		if (bit) {
			unsigned int len, pos;

			/* input match length and position */
			if (!blz_getgamma_safe(&bs, &len)) {
				return BLZ_ERROR;
			}
			if (!blz_getgamma_safe(&bs, &pos)) {
				return BLZ_ERROR;
			}

			len += 2;
			pos -= 2;

			if (!bs.srclen--) {
				return BLZ_ERROR;
			}

			pos = (pos << 8) + *bs.source++ + 1;

			if (pos > (depacked_length - bs.dstlen)) {
				return BLZ_ERROR;
			}

			if (len > bs.dstlen) {
				return BLZ_ERROR;
			}

			bs.dstlen -= len;

			/* copy match */
			{
				const unsigned char *ppos = bs.destination - pos;
				int i;
				for (i = len; i > 0; --i) {
					*bs.destination++ = *ppos++;
				}
			}

			length += len;
		}
		else {
			/* copy literal */
			if (!bs.srclen-- || !bs.dstlen--) {
				return BLZ_ERROR;
			}
			*bs.destination++ = *bs.source++;

			length++;
		}
	}

	/* return decompressed length */
	return length;
}
