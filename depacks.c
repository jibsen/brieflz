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
	const unsigned char *src;
	unsigned char *dst;
	unsigned int src_avail;
	unsigned int dst_avail;
	unsigned int tag;
	unsigned int bitcount;
};

static int
blz_getbit_safe(struct blz_state *bs, unsigned int *result)
{
	unsigned int bit;

	/* check if tag is empty */
	if (!bs->bitcount--) {
		if (bs->src_avail < 2) {
			return 0;
		}
		bs->src_avail -= 2;

		/* load next tag */
		bs->tag = (unsigned int) bs->src[0]
		       | ((unsigned int) bs->src[1] << 8);
		bs->src += 2;
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
blz_depack_safe(const void *src, unsigned int src_size,
                void *dst, unsigned int depacked_size)
{
	struct blz_state bs;
	unsigned int dst_size = 1;
	unsigned int bit;

	/* check for length == 0 */
	if (depacked_size == 0) {
		return 0;
	}

	bs.src = (const unsigned char *) src;
	bs.src_avail = src_size;
	bs.dst = (unsigned char *) dst;
	bs.dst_avail = depacked_size;
	bs.bitcount = 0;

	/* first byte verbatim */
	if (!bs.src_avail-- || !bs.dst_avail--) {
		return BLZ_ERROR;
	}
	*bs.dst++ = *bs.src++;

	/* main decompression loop */
	while (dst_size < depacked_size) {
		if (!blz_getbit_safe(&bs, &bit)) {
			return BLZ_ERROR;
		}

		if (bit) {
			unsigned int len, off;

			/* input match length and offset */
			if (!blz_getgamma_safe(&bs, &len)) {
				return BLZ_ERROR;
			}
			if (!blz_getgamma_safe(&bs, &off)) {
				return BLZ_ERROR;
			}

			len += 2;
			off -= 2;

			if (!bs.src_avail--) {
				return BLZ_ERROR;
			}

			off = (off << 8) + (unsigned int) *bs.src++ + 1;

			if (off > depacked_size - bs.dst_avail) {
				return BLZ_ERROR;
			}

			if (len > bs.dst_avail) {
				return BLZ_ERROR;
			}

			bs.dst_avail -= len;

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
			if (!bs.src_avail-- || !bs.dst_avail--) {
				return BLZ_ERROR;
			}
			*bs.dst++ = *bs.src++;

			dst_size++;
		}
	}

	/* return decompressed size */
	return dst_size;
}
