package engineering.swat.nescio.algorithms;

public class ToZeros {

	public static byte[] apply(byte[] bytes) {
		byte[] output = new byte[bytes.length];
		for (int i =0; i< bytes.length; i++)
			output[i] = 0;
		return output;
	}

}
