package engineering.swat.nescio;

import java.util.List;
import java.util.function.Function;

public class TransformationDescription {
	private Function<byte[], byte[]> anonymizingFunction;
	private List<Range> ranges;
	
	public TransformationDescription(Function<byte[], byte[]> anonymizingFunction, List<Range> ranges) {
		super();
		this.anonymizingFunction = anonymizingFunction;
		this.ranges = ranges;
	}
	
	public Function<byte[], byte[]> getAnonymizingFunction() {
		return anonymizingFunction;
	}
	
	public List<Range> getRanges() {
		return ranges;
	}
	
	
}
