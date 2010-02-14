import javax.swing.JButton;
import javax.swing.JFrame;

import java.awt.*;
import java.awt.event.*;

import java.io.IOException;
import java.io.FileWriter;
import java.io.BufferedWriter;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class ScalarInference implements MessageListener,ActionListener
{
	private MoteIF moteIF;
	private final static int NUM_OF_TEMP_READINGS = 5;
	BufferedWriter outBr;
	FileWriter tempFile; 
	
	public ScalarInference()
	{
		this.moteIF = new MoteIF(PrintStreamMessenger.err);
		this.moteIF.registerListener(new TempMsg(), this);
		try
		{
			outBr = new BufferedWriter(new FileWriter("light.txt"));
		}
		catch(IOException ie)
		{
			ie.printStackTrace();
		}
		
		createAndShowGUI();
	}
	
	public void actionPerformed(ActionEvent ae)
	{
		try
		{
			outBr.close();
		}
		catch(IOException ie)
		{
			ie.printStackTrace();
		}
	}
	
	public void messageReceived(int to, Message message)
	{
		short[] temperatureReadings = new short[NUM_OF_TEMP_READINGS];
		int[] timestamps = new int[NUM_OF_TEMP_READINGS];
		if (message instanceof TempMsg)
		{
			TempMsg tempMsg = (TempMsg)message;
			temperatureReadings = tempMsg.get_temperature();	
			timestamps = tempMsg.get_timestamp();
			for (int i = 0; i < NUM_OF_TEMP_READINGS; i++)
			{
				try
				{
					outBr.write(temperatureReadings[i]  + " ");
					outBr.write(timestamps[i] + "\n");
					System.out.println(temperatureReadings[i]);
				
				}
				catch (IOException ie)
				{
					ie.printStackTrace();
				}
			}
		}
	}
	
	private void createAndShowGUI()
	{
		JFrame frame = new JFrame("Sensor Calibration");
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		JButton button = new JButton("Click here to stop recording data");
		
		button.addActionListener(this);
		frame.getContentPane().add(button);
		frame.pack();
		frame.setVisible(true);
		
	}
	
	public static void main(String[] args)
	{
		// new ScalarInference();
		javax.swing.SwingUtilities.invokeLater(new Runnable() {
			public void run() {
				new ScalarInference();
			}
		});
	}
	
}