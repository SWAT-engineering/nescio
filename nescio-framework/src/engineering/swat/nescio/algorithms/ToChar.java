package engineering.swat.nescio.algorithms;

import java.io.UnsupportedEncodingException;

public class ToChar {

	public static byte[] apply(byte[] bytes, String ch, String charset) {
		if (ch == null)
			throw new RuntimeException("Argument to ToChar.apply not provided");
		if (ch.length() != 1)
			throw new RuntimeException("Argument to ToChar.apply must be a string of length 1");
		
		byte[] output = new byte[bytes.length];
		byte replacement;
		try {
			replacement = ch.getBytes(charset)[0];
			for (int i =0; i< bytes.length; i++)
				output[i] = replacement;
			return output;
		} catch (UnsupportedEncodingException e) {
			throw new RuntimeException(e);
		
		}
	}

	public static byte[] applyASCII(byte[] bytes, String ch) {
		return apply(bytes, ch, "US-ASCII");
	}
	
	public static byte[] applyUTF8(byte[] bytes, String ch) {
		return apply(bytes, ch, "UTF-8");
	}
	
	public static byte[] applyISO88591(byte[] bytes, String ch) {
		return apply(bytes, ch, "ISO-8859-1");
	}
}
