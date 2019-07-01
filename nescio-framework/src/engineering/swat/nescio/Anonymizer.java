package engineering.swat.nescio;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.util.Map;

public abstract class Anonymizer {

	public abstract Map<String, TransformationDescription> match(Path uri) throws MatchingException;
	
	public void anonymize(Path input, Path output) throws IOException, MatchingException {
		Map<String, TransformationDescription> trafos = match(input);
		Files.copy(input, output, StandardCopyOption.REPLACE_EXISTING);
		try (FileChannel fc = FileChannel.open(output, StandardOpenOption.READ, StandardOpenOption.WRITE)) {
			for (String trafoName : trafos.keySet()) {
				TransformationDescription t = trafos.get(trafoName);
				for (Range range : t.getRanges()) {
					fc.position(range.getOffset());
					byte[] bytes = new byte[range.getLength()];
					ByteBuffer buffer = ByteBuffer.allocate(range.getLength());
					fc.read(buffer);
					buffer.rewind();
					buffer.get(bytes);
				
					// Apply transformation
				
					byte[] transformedBytes = t.getAnonymizingFunction().apply(bytes);
			
					fc.position(range.getOffset());
					ByteBuffer writingBuffer = ByteBuffer.wrap(transformedBytes);
					fc.write(writingBuffer);
				}
			
			}
		}
		
	}
}
