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
	using System.IO;

	public class StreamCompressor
	{
		void Decompress(Stream from, Stream to)
		{
			byte[] header = new byte[8];

			if (from.Read(header, 0, 8) != 8)
			{
				throw(new Exception("BriefLZ: unable to read header from stream"));
			}

			int tag = BitConverter.toInt32(header, 0);
			int bufferSize = BitConverter.toInt32(header, 4);

			byte[] src = new byte[bufferSize];

			int dstSize = aPLib.aPsafe_get_orig_size(src);

			// allocate mem
			byte[] dst = new byte[dstSize];

			// process stream
			while (from.Read(src, 0, bufferSize) > 0)
			{
				// decompress data
				int depackedSize = DllInterface.blz_depack(src, dst);

				// write decompressed data
				to.Write(dst, 0, depackedSize);
			}
		}
	}
}
