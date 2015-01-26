//
// BriefLZ  -  small fast Lempel-Ziv
//
// C# wrapper
//
// Copyright (c) 2002-2015 by Joergen Ibsen / Jibz
// All Rights Reserved
//
// http://www.ibsensoftware.com/
//

namespace IbsenSoftware.BriefLZ
{
	using System.Runtime.InteropServices;

	public class DllInterface
	{
		[DllImport("brieflz.dll")]
		public static extern int blz_pack(
			[In]  byte[] source,
			[Out] byte[] destination,
			      int length,
			[In]  byte[] workmem
		);

		[DllImport("brieflz.dll")]
		public static extern int blz_depack(
			[In]  byte[] source,
			[Out] byte[] destination,
			      int depacked_length
		);

		[DllImport("brieflz.dll")]
		public static extern int blz_depack_safe(
			[In]  byte[] source,
			      int srclen,
			[Out] byte[] destination,
			      int depacked_length
		);

		[DllImport("brieflz.dll")]
		public static extern int blz_workmem_size(int length);

		[DllImport("brieflz.dll")]
		public static extern int blz_max_packed_size(int length);

		[DllImport("brieflz.dll")]
		public static extern uint blz_crc32(
			[In]  byte[] source,
			      int length,
			      uint initial_crc32
		);
	}
}
