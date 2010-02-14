import javax.swing.JButton;
import javax.swing.JFrame;

import java.awt.*;
import java.awt.event.*;

import java.io.IOException;
import java.io.FileWriter;
import java.io.FileReader;
import java.io.BufferedWriter;
import java.io.BufferedReader;
import java.io.File;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

import javax.swing.*;
import javax.swing.filechooser.*;
import javax.swing.JFileChooser;

import javax.swing.JTabbedPane;
import java.awt.TextArea;

public class BayesMote implements MessageListener, ActionListener
{
	private MoteIF moteIF, condProbMote;
	private final static int NUM_OF_TEMP_READINGS = 5;
	
	JFrame frame;
	JLabel mote1StateText, mote1StateProb, mote2StateText, mote2StateProb, condProbFilename;
	JButton openCondProbFileBtn, clearLog;
	JFileChooser probTableFileChoose;
	TextArea logText, condProbFileContent;
	JComboBox selectMoteList;
	int moteNumUpdateCondTable;

	private static final int NUM_OF_TEMP_STATES = 2;
	private static final int NUM_OF_LIGHT_STATES = 3;
	private static final int NUM_OF_MOTE_STATES = 5;
	short [][]condProbValuesShort = new short[NUM_OF_LIGHT_STATES * NUM_OF_TEMP_STATES] [NUM_OF_MOTE_STATES];
	
	public BayesMote()
	{
		this.moteIF = new MoteIF(PrintStreamMessenger.err);
		this.condProbMote = new MoteIF(PrintStreamMessenger.err);
		this.moteIF.registerListener(new EventMsg(), this);
		
		
		createAndShowGUI();
	}
	public void readAndSendCondProbTbl()
	{
		CondProbMsg condProbMsg = new CondProbMsg();
		String condProbTableLine = new String();
		
		BufferedReader br;
		double [][] condProbValues = new double[NUM_OF_TEMP_STATES * NUM_OF_LIGHT_STATES][NUM_OF_MOTE_STATES];
		String txtLine = new String();
		String[] condProbTextLine;
		File condProbFile;
			
		int colCounter = 0;
			
		probTableFileChoose.setCurrentDirectory(new java.io.File("."));
		if (probTableFileChoose.showOpenDialog(null) == JFileChooser.APPROVE_OPTION)
		{
			condProbFile = probTableFileChoose.getSelectedFile();
				
			condProbFileContent.setText("");
			condProbFilename.setText("Selected file: " + condProbFile.getName());
				
			try
			{
				br = new BufferedReader(new FileReader(condProbFile.getAbsolutePath()));
				
				/// store Samiam values into a text file
				while ((txtLine = br.readLine()) !=null)
				{
					condProbTextLine = txtLine.split("\\t");
					// System.out.println(txtLine);
					for (int x=0; x<condProbTextLine.length; x++)
					{
						condProbValues[x][colCounter] = Double.parseDouble(condProbTextLine[x]);
							
					}
					colCounter ++;
				}
				
				br.close();
			}
			catch(IOException ie)
			{
				ie.printStackTrace();
			}	
				
			for (int i = 0; i < (NUM_OF_LIGHT_STATES * NUM_OF_TEMP_STATES); i++)
			{
				condProbTableLine = "";
				for (int j = 0; j < NUM_OF_MOTE_STATES; j++)
				{
					condProbValuesShort[i][j] = (short)(condProbValues[i][j] * 100);
					System.out.print("" + condProbValuesShort[i][j] + "\t");
					condProbTableLine = condProbTableLine + "" + condProbValuesShort[i][j];
					if (j < (NUM_OF_MOTE_STATES - 1))
					{
						condProbTableLine += "\t";
					}
				}
				System.out.println("\n");
				condProbFileContent.append(condProbTableLine + "\n");
					
			}
			Object[] options = { "Yes", "No" };
			int sendTable = JOptionPane.showOptionDialog(frame, "Send conditional probability table to Mote " + moteNumUpdateCondTable + "?", "Confirm",JOptionPane.DEFAULT_OPTION, JOptionPane.WARNING_MESSAGE,  null, options, options[0]);
			
			if (sendTable == JOptionPane.YES_OPTION)
			{
				try
				{						
					condProbMsg.set_probability(condProbValuesShort);
					
					//condProbMsg.set_finalDestAddr((short)(2));
					condProbMsg.set_finalDestAddr((short)(moteNumUpdateCondTable));
					
					condProbMote.send(MoteIF.TOS_BCAST_ADDR, condProbMsg);
				}
				catch (IOException ioe)
				{
					System.out.println(ioe.toString());
				}	
			}
			condProbFileContent.repaint();
		}	
	}
	
	public void actionPerformed(ActionEvent ae)
	{
		if (ae.getSource() == openCondProbFileBtn)
		{
			readAndSendCondProbTbl();
		} 
		else if (ae.getSource() == clearLog)
		{
			logText.setText("");	
		}
		else if (ae.getSource() == selectMoteList)
		{
			
			//JComboBox cb = (JComboBox)ae.getSource();
			moteNumUpdateCondTable = selectMoteList.getSelectedIndex() + 1;
			System.out.println(moteNumUpdateCondTable);
		}
			
		
	}
	
	public void messageReceived(int to, Message message)
	{
		EventMsg eventMsg;
		String logLine = new String();
		String curMoteState = new String();
		if (message instanceof EventMsg)
		{
			eventMsg = (EventMsg)message;
			byte []moteEvent = new byte[1];
			short []eventProb = new short[1];
			
			eventProb = eventMsg.get_prob();
			moteEvent = eventMsg.get_moteEvent();
			int moteNum = eventMsg.get_srcAddr();
			
			int moteEventInt = moteEvent[0];
			int eventProbInt = eventProb[0];
			
			switch (moteEventInt)
			{
				case 0:
					curMoteState = "in a closed fridge";
					break;
				case 1:
					curMoteState = "in an open fridge";
					break;
					
				case 2:
					curMoteState = "outside, really bright";
					break;
					
				case 3:
					curMoteState = "outside, in room";
					break;
					
				case 4:
					curMoteState = "outside, light off";
					break;
			}
			
			logLine = "Mote " + moteNum + " is " + curMoteState + " with a prob of:" + eventProbInt;
 			logText.append(logLine + "\n");
			
			System.out.println(logLine);
			
			if (moteNum == 1)
			{ 
				mote1StateText.setText(curMoteState);	
				mote1StateProb.setText(Integer.toString(eventProbInt));			
			}
			else 
			{
				mote2StateText.setText(curMoteState);
				mote2StateProb.setText(Integer.toString(eventProbInt));		
			}
			
			
			
		}
	}
	
	private void createAndShowGUI()
	{
		frame = new JFrame("RatPack: proof of concept");
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		
		// Create tabbed panel
		JTabbedPane pnlMain = new JTabbedPane();
		JPanel pnlMoteState = new JPanel(new GridLayout(0, 2)); 
		pnlMain.addTab("Mote state", pnlMoteState);
		pnlMain.setSelectedIndex(0);

		JPanel pnlProb = new JPanel(new BorderLayout()); 
		pnlMain.addTab("Probability Table", pnlProb);
		
		JPanel pnlLog = new JPanel(new BorderLayout());
		pnlMain.addTab("Log", pnlLog);
				
		// Components of "Mote State" tab
		mote1StateText = new JLabel("-");
		mote1StateProb = new JLabel("0");
		mote2StateText = new JLabel("-");
		mote2StateProb = new JLabel("0");
		//mote1StateNext = new JLabel("Now undefined");
				
		pnlMoteState.add(new JLabel("Mote 1 is in state: "));
		pnlMoteState.add(mote1StateText);
		pnlMoteState.add(new JLabel("with probability: "));
		pnlMoteState.add(mote1StateProb);
		
		pnlMoteState.add(new JLabel("Mote 2 is in state: "));
		pnlMoteState.add(mote2StateText);
		pnlMoteState.add(new JLabel("with probability: "));
		pnlMoteState.add(mote2StateProb);

		//pnlMoteState.add(new JLabel("Next state expected to be: "));
		//pnlMoteState.add(mote1StateNext);		
		
		// Components of "Probability Table" tab
		JPanel pnlProbBtn = new JPanel(new FlowLayout());
		
		String[] selectMoteListItems = {"Mote 1", "Mote 2"};
		selectMoteList = new JComboBox(selectMoteListItems);
		moteNumUpdateCondTable = 1; // selected Mote to update its cond prob table
		selectMoteList.setSelectedIndex(moteNumUpdateCondTable - 1);
		selectMoteList.addActionListener(this);
		
		openCondProbFileBtn = new JButton("Select file");
		openCondProbFileBtn.addActionListener(this);
		
		JPanel pnlFileContent = new JPanel(new GridLayout(2,1));
		
		condProbFilename = new JLabel();
		
		condProbFileContent = new TextArea("", 1,1, TextArea.SCROLLBARS_NONE);
		condProbFileContent.setEditable(false);
		
		probTableFileChoose = new JFileChooser();
		probTableFileChoose.setFileSelectionMode(JFileChooser.FILES_ONLY);
		
		FileNameExtensionFilter filter = new FileNameExtensionFilter(
				"Text files", "txt");
		probTableFileChoose.addChoosableFileFilter(filter);
		
		pnlProbBtn.add(new JLabel("Update table for "));
		pnlProbBtn.add(selectMoteList);
		pnlProbBtn.add(openCondProbFileBtn);
		pnlProb.add(pnlProbBtn, BorderLayout.NORTH);
		
		pnlFileContent.add(condProbFilename);
		pnlFileContent.add(condProbFileContent);
		pnlProb.add(pnlFileContent, BorderLayout.CENTER);
		
		// Components of "Log" tab
		logText = new TextArea("", 70, 0, TextArea.SCROLLBARS_VERTICAL_ONLY);
		logText.setEditable(false);
		
		clearLog = new JButton("Clear");
		clearLog.addActionListener(this);
		
		pnlLog.add(logText, BorderLayout.CENTER);
		pnlLog.add(clearLog, BorderLayout.SOUTH);
		
		frame.getContentPane().add(pnlMain);
		frame.setSize(400,300);
		//frame.pack();
		frame.setVisible(true);
		
	}
	
	public static void main(String[] args)
	{
		// new ScalarInference();
		javax.swing.SwingUtilities.invokeLater(new Runnable() {
			public void run() {
				new BayesMote();
			}
		});
	}
	
}