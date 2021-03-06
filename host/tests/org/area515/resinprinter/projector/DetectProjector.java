package org.area515.resinprinter.projector;

import gnu.io.CommPortIdentifier;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.area515.resinprinter.printer.ComPortSettings;
import org.area515.resinprinter.serial.JSSCCommPort;
import org.area515.resinprinter.serial.SerialCommunicationsPort;
import org.area515.resinprinter.serial.SerialManager;
import org.area515.resinprinter.serial.SerialManager.DetectedResources;
import org.area515.resinprinter.server.HostProperties;
import org.junit.Assert;
import org.junit.Test;
import org.mockito.Mockito;

public class DetectProjector {
    private static final Logger logger = LogManager.getLogger();
    
	@Test
	public void noErrorsDetectingProjector() {
		logger.info("Projector detection test.");

		boolean hasFound = false;
		ComPortSettings newComPortSettings = new ComPortSettings();
		ArrayList<CommPortIdentifier> identifiers = new ArrayList<CommPortIdentifier>(Collections.list(CommPortIdentifier.getPortIdentifiers()));
		for (CommPortIdentifier currentIdentifier : identifiers) {
			newComPortSettings.setPortName(currentIdentifier.getName());
			
			logger.info("Attempting detection on port:{}", currentIdentifier.getName());
			SerialCommunicationsPort port = new JSSCCommPort();
			DetectedResources resources = SerialManager.Instance().getProjectorModel(port, newComPortSettings);
			if (resources != null) {
				hasFound = true;
			}
			logger.info("  JSSCCommPort projector detection:{}", resources);
			
			/*port = new RXTXEventBasedCommPort();
			logger.info("  RXTXEventBasedCommPort projector detection:{}", SerialManager.Instance().getProjectorModel(port, newComPortSettings, false));
			
			port = new RXTXSynchronousReadBasedCommPort();
			logger.info("  RXTXSynchronousReadBasedCommPort projector detection:{}", SerialManager.Instance().getProjectorModel(port, newComPortSettings, false));*/
		}
		Assert.assertTrue(hasFound);
	}
}
