package engineering.swat.nescio;

public class Range {
	private int offset;
	private int length;
	
	public Range(int offset, int length) {
		super();
		this.offset = offset;
		this.length = length;
	}

	public int getOffset() {
		return offset;
	}

	public int getLength() {
		return length;
	}
	
	@Override
	public String toString() {
		return "Offset: " + offset + ", length: " + length;
	}
	
	
}
