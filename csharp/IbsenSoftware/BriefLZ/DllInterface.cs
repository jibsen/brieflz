//
// BriefLZ  -  small fast Lempel-Ziv
//
// C# wrapper
//
// Copyright (c) 2002-2004 by Joergen Ibsen / Jibz
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
		public static extern int blz_workmem_size(int length);

		[DllImport("brieflz.dll")]
		public static extern int blz_max_packed_size(int length);

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
	}
}
