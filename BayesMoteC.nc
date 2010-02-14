#include <Timer.h>
#include "headers/BayesMoteApp.h"
#include "PacketFormats/CondProbMsg.h"
//#include "PacketFormats/TempMsg.h"
#include "PacketFormats/CondProbRadioMsg.h"
#include "PacketFormats/EventMsg.h"
// #define LED_DEBUG

module BayesMoteC
{
	uses interface Timer<TMilli> as SensorTimer;
	uses interface Leds;
	uses interface Boot;
	
	uses interface SplitControl as AMControl;
	uses interface SplitControl as AMSerialControl;
	
	/// For sending event messages and Conditional Probability table messages

	uses interface AMSend as AMCondProbSend;
	uses interface Packet as CondProbPacket;
	uses interface AMPacket as AMCondProbPacket;
	
	uses interface Receive as CondProbReceive;
	uses interface Receive as CondProbRadioReceive;
	
	// !!
	uses interface Receive as EventRadioReceive;
	uses interface AMSend as AMEventRadioSend;
	uses interface Packet as EventRadioPacket;
	uses interface AMPacket as AMEventRadioPacket;
	
	/// For scalar inference
	uses interface AMSend as AMEventSend;
	uses interface Packet as EventPacket;
	uses interface AMPacket as AMEventPacket;
	
	/// to read the sensor readings
	uses interface Read<uint16_t> as TempRead;
	uses interface Read<uint16_t> as LightRead;
}

implementation
{
	bool radioBusy = FALSE;
	bool sendEventMsgToBS = FALSE;
	uint8_t tempMeasureCounter, lightMeasureCounter;
	///packet to be sent
	message_t pkt;
	struct SensorState sensorStates[NUM_OF_TEMP_STATES];
	struct CondProbTbl condProbTbl[NUM_OF_TEMP_STATES]; /// the number of cond prob tables = num of temp states. This can be extended for more generic problems.
	uint8_t lightState; ///< indicate whether light is turned on or not.
	uint8_t moteState; 
	
	uint8_t eventNum; ///< keeps track of events that have occured. Reset when EventMsg sent
	EventMsg eventMsg;
	CondProbMsg condProbPkt;
	
	bool recdEventMsgFromAnotherMote;
	EventRadioMsg recdEventRadioMsg;
		
	/// Tasks
	task void sendEventMsg()
	{
		EventMsg *eventPkt = (EventMsg *) (call EventPacket.getPayload(&pkt, NULL));
		
		if (recdEventMsgFromAnotherMote == TRUE)
		{
			recdEventMsgFromAnotherMote = FALSE;
			eventPkt -> srcAddr = recdEventRadioMsg.srcAddr;
			eventPkt -> moteEvent[0] = recdEventRadioMsg.moteEvent[0];
			eventPkt -> prob[0] = recdEventRadioMsg.prob[0];
		}
		else
		{
			eventNum = 0;
			eventPkt -> srcAddr = TOS_NODE_ID;	
			eventPkt -> moteEvent[0] = eventMsg.moteEvent[0];
			eventPkt -> prob[0] = eventMsg.prob[0];
		}
		
		if (radioBusy == FALSE)
		{	
			if (call AMEventSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(EventMsg)) == SUCCESS)
			{
				radioBusy = TRUE;
			}
		}
	}
	
	task void sendEventRadioMsg()
	{
		EventRadioMsg *eventRadioPkt = (EventRadioMsg *) (call EventRadioPacket.getPayload(&pkt, NULL));
		
		eventNum = 0;
		eventRadioPkt -> srcAddr = TOS_NODE_ID;	
		eventRadioPkt -> moteEvent[0] = eventMsg.moteEvent[0];
		eventRadioPkt -> prob[0] = eventMsg.prob[0];
		
		if (radioBusy == FALSE)
		{	
			if (call AMEventRadioSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(EventRadioMsg)) == SUCCESS)
			{
				radioBusy = TRUE;
			}
		}
	}
	
	task void sendCondProbMsg()
	{
		//TempMsg* condProbRadioPkt = (TempMsg*) (call EventPacket.getPayload(&pkt,NULL));
		uint8_t i, j;
		
		CondProbRadioMsg* condProbRadioPkt = (CondProbRadioMsg*) (call CondProbPacket.getPayload(&pkt,NULL));
		
		condProbRadioPkt -> finalDestAddr = condProbPkt.finalDestAddr;
		
		// just copy from data, received earlier
		for (i = 0; i < (NUM_OF_TEMP_STATES * NUM_OF_LIGHT_STATES) ; i++)
		{
			for (j = 0; j < NUM_OF_MOTE_STATES; j++)
			{
				condProbRadioPkt -> probability[i][j] = condProbPkt.probability[i][j];
			}
			
		}
		
		//condProbRadioPkt -> probability = condProbPkt->probability;
		
		if (radioBusy == FALSE)
		{	
			if ( call AMCondProbSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(TempMsg) ) == SUCCESS)
			{
				radioBusy = TRUE;
			}
		}
	}
	
	/// Utility functions
	void reportProblem()
	{
		call Leds.led0Toggle();
		call Leds.led1Toggle();
		call Leds.led2Toggle();
	}
	
	void reportSendSuccess()
	{
		// call Leds.led2Toggle();
	}
	
	/**
	 * Name: initCondProb()
	 * Author: Galiia Khasanova and Siddhu Warrier
	 * Purpose: Initialises the Conditional probability table with the appropriate 
	 * conditional probability values in the beginning. Overriding poss
	 **/
	void initCondProb()
	{		/// These are a bunch of hard-coded values. This function is executed just once.
		
		/// step 1: For temp = FRIDGE. When the row = 0, light = LIGHT_ROOM, else light = LIGHT_BRIGHT, else light = LIGHT_OFF
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_ROOM][MOTE_FRIDGE_CLOSED] = 0;
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_ROOM][MOTE_FRIDGE_OPEN] = 80;
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_ROOM][MOTE_OUTSIDE_BRIGHT] = 0;
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_ROOM][MOTE_OUTSIDE_ROOM] = 10;
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_ROOM][MOTE_OUTSIDE_OFF] = 10;
		
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_BRIGHT][MOTE_FRIDGE_CLOSED] = 0;
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_BRIGHT][MOTE_FRIDGE_OPEN] = 30;
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_BRIGHT][MOTE_OUTSIDE_BRIGHT] = 70;
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_BRIGHT][MOTE_OUTSIDE_ROOM] = 0;
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_BRIGHT][MOTE_OUTSIDE_OFF] = 0;
		
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_OFF][MOTE_FRIDGE_CLOSED] = 90;
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_OFF][MOTE_FRIDGE_OPEN] = 0;
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_OFF][MOTE_OUTSIDE_BRIGHT] = 0;
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_OFF][MOTE_OUTSIDE_ROOM] = 0;
		condProbTbl[TEMP_FRIDGE].condProb[LIGHT_OFF][MOTE_OUTSIDE_OFF] = 10;
		
		/// step 2: For temp = OUTSIDE. When the row = 0,light = LIGHT_ROOM, else light = LIGHT_BRIGHT, else light = LIGHuint8_t i, j, k;T_OFF
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_ROOM][MOTE_FRIDGE_CLOSED] = 0;
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_ROOM][MOTE_FRIDGE_OPEN] = 20;
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_ROOM][MOTE_OUTSIDE_BRIGHT] = 0;
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_ROOM][MOTE_OUTSIDE_ROOM] = 75;
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_ROOM][MOTE_OUTSIDE_OFF] = 5;
		
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_BRIGHT][MOTE_FRIDGE_CLOSED] = 0;
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_BRIGHT][MOTE_FRIDGE_OPEN] = 10;
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_BRIGHT][MOTE_OUTSIDE_BRIGHT] = 90;
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_BRIGHT][MOTE_OUTSIDE_ROOM] = 0;
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_BRIGHT][MOTE_OUTSIDE_OFF] = 0;
		
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_OFF][MOTE_FRIDGE_CLOSED] = 20;
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_OFF][MOTE_FRIDGE_OPEN] = 0;
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_OFF][MOTE_OUTSIDE_BRIGHT] = 0;
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_OFF][MOTE_OUTSIDE_ROOM] = 0;
		condProbTbl[TEMP_OUTSIDE].condProb[LIGHT_OFF][MOTE_OUTSIDE_OFF] = 80;
	}
	
	/// Question: Reduce computational complexity by passing arguments, or save memory? Choosing the latter here
	void changeMoteState()
	{
		/**
		 * Note. Implementation gets much more complex, as a depth first traversal 
		 * will have to be done if there are more than two sensors. 
		 **/
		uint8_t i, j, maxProb = 0;
	
		
		struct CondProbTbl *tempCondProbTbl;
		/// The final sensor contains the conditional probability tables. For multiple sensors, it would look a little different. Now this could be done simpler, but for completeness, we use two counter variables. Too tired to really explain ;)
		for (i = 0; i < NUM_OF_TEMP_STATES; i++)
		{
			if (sensorStates[i].enabled == TRUE)
			{
				break;
			}
		}
		
		//change!
		moteState = 4; //whatever value, it will be changed in the loop
		
		///choose the appropriate conditional probability table depending on the state
		tempCondProbTbl = sensorStates[i].condProbTbl;
		
		for (j = 0; j < NUM_OF_MOTE_STATES; j++)
		{
			if (tempCondProbTbl->condProb[lightState][j] > maxProb)
			{
				maxProb = tempCondProbTbl->condProb[lightState][j];
				moteState = j;
			}
		}
		
		
		
		if (moteState == MOTE_FRIDGE_CLOSED)
		{
			call Leds.led0On();
			call Leds.led1On();
			call Leds.led2Off();
		}
		if (moteState == MOTE_FRIDGE_OPEN)
		{
			call Leds.led0On();
			call Leds.led1Off();
			call Leds.led2On();
		}
		if (moteState == MOTE_OUTSIDE_ROOM)
		{
			call Leds.led0On();
			call Leds.led1Off();
			call Leds.led2Off();
		}
		if (moteState == MOTE_OUTSIDE_OFF)
		{
			call Leds.led0Off();
			call Leds.led1On();
			call Leds.led2Off();
		}
		if (moteState == MOTE_OUTSIDE_BRIGHT)
		{
			call Leds.led0Off();
			call Leds.led1Off();
			call Leds.led2On();
		}
		
		
		/// add it to event message event
		sendEventMsgToBS = TRUE;
		eventMsg.moteEvent[0] = moteState;
		eventMsg.prob[0] = tempCondProbTbl->condProb[lightState][moteState];
	}

	/// Events
	event void Boot.booted()
	{
		uint8_t i;
		
		tempMeasureCounter = lightMeasureCounter = 0;
		
		initCondProb(); ///< this initialises the conditional prob table with a given model. This can be overriden using a CondProb message (T.B.Impl).
		
		///initialising Sensor states. None of them are enabled at the start
		sensorStates[0].stateName = TEMP_FRIDGE;
		sensorStates[1].stateName = TEMP_OUTSIDE;
		lightState = LIGHT_OFF;
		eventNum = 0;
		
		recdEventMsgFromAnotherMote = FALSE;
		
		for (i = 0;  i < NUM_OF_TEMP_STATES; i++)
		{
			sensorStates[i].enabled = FALSE;
			sensorStates[i].condProbTbl = &condProbTbl[i];
		}
		
		call AMControl.start();
		call AMSerialControl.start();
	}
	
	event void AMControl.startDone(error_t status)
	{
		if (status == SUCCESS)
		{
			call SensorTimer.startPeriodic(TIMER_TICK);
		}
		else
		{
			call AMControl.start();
		}	
	}
	
	event void AMSerialControl.startDone(error_t status)
	{
		if (status != SUCCESS)
		{
			call AMSerialControl.start();
		}
	}
	
	event void AMControl.stopDone(error_t status)
	{
	}
	
	event void AMSerialControl.stopDone(error_t status)
	{
	}
	
	event void AMCondProbSend.sendDone(message_t* msg, error_t status)
	{
		if (&pkt == msg)
		{
			radioBusy = FALSE;
			reportSendSuccess();
		}
		
	}
	
	event void AMEventSend.sendDone(message_t* msg, error_t status)
	{
		if (&pkt == msg)
		{
			radioBusy = FALSE;
			sendEventMsgToBS = FALSE;
			reportSendSuccess();
		}
	}
	
	event void AMEventRadioSend.sendDone(message_t* msg, error_t status)
	{
		if (&pkt == msg)
		{
			radioBusy = FALSE;
			sendEventMsgToBS = FALSE;
			reportSendSuccess();
		}
	}
	
	event message_t *EventRadioReceive.receive(message_t* msg, void * payload, uint8_t len)
	{
		EventRadioMsg * recdMsg = (EventRadioMsg *) payload;
		recdEventRadioMsg = *recdMsg; ///< copy the data into this structure 
		recdEventMsgFromAnotherMote = TRUE; ///< indicate that you've received an event message from another mote.
		
		post sendEventMsg();
		
		return msg;
	}
	
	event message_t *CondProbRadioReceive.receive(message_t* msg, void * payload, uint8_t len)
	{
		//TempMsg * recdMsg = (TempMsg *) payload;
		CondProbRadioMsg * recdMsg = (CondProbRadioMsg *) payload;
		
		uint8_t i, j, k;	
		struct CondProbTbl *tempCondProbTbl;
		
		
		if (recdMsg -> finalDestAddr == TOS_NODE_ID)
		{
			//call Leds.led1Toggle();
			call Leds.led0On();
			call Leds.led1On();
			call Leds.led2On();
			
/// clear old values of cond prob table;
// just to test
			/*tempCondProbTbl = sensorStates[0].condProbTbl;
			
			tempCondProbTbl -> condProb[0][0] = 0;
			tempCondProbTbl -> condProb[0][1] = 89;
			tempCondProbTbl -> condProb[0][2] = 0;
			tempCondProbTbl -> condProb[0][3] = 6;
			tempCondProbTbl -> condProb[0][4] = 5;
			
			tempCondProbTbl -> condProb[1][0] = 0;
			tempCondProbTbl -> condProb[1][1] = 25;
			tempCondProbTbl -> condProb[1][2] = 75;
			tempCondProbTbl -> condProb[1][3] = 0;
			tempCondProbTbl -> condProb[1][4] = 0;
			
			tempCondProbTbl -> condProb[2][0] = 47;
			tempCondProbTbl -> condProb[2][1] = 0;
			tempCondProbTbl -> condProb[2][2] = 0;
			tempCondProbTbl -> condProb[2][3] = 0;
			tempCondProbTbl -> condProb[2][4] = 63;
			
		
			tempCondProbTbl = sensorStates[1].condProbTbl;
			
			tempCondProbTbl -> condProb[0][0] = 0;
			tempCondProbTbl -> condProb[0][1] = 12;
			tempCondProbTbl -> condProb[0][2] = 0;
			tempCondProbTbl -> condProb[0][3] = 74;
			tempCondProbTbl -> condProb[0][4] = 14;
			
			tempCondProbTbl -> condProb[1][0] = 0;
			tempCondProbTbl -> condProb[1][1] = 17;
			tempCondProbTbl -> condProb[1][2] = 81;
			tempCondProbTbl -> condProb[1][3] = 2;
			tempCondProbTbl -> condProb[1][4] = 0;
			
			tempCondProbTbl -> condProb[2][0] = 24;
			tempCondProbTbl -> condProb[2][1] = 0;
			tempCondProbTbl -> condProb[2][2] = 0;
			tempCondProbTbl -> condProb[2][3] = 0;
			tempCondProbTbl -> condProb[2][4] = 76;
			*/
			

///--- copy from CondProbReceive.receive		
			tempCondProbTbl = sensorStates[0].condProbTbl;
			for (i = 0; i < (NUM_OF_TEMP_STATES * NUM_OF_LIGHT_STATES) /2 ; i++)
			{
				for (j = 0; j < NUM_OF_MOTE_STATES; j++)
				{
					tempCondProbTbl -> condProb[i][j] = recdMsg->probability[i][j];
				}
			}
		
			tempCondProbTbl = sensorStates[1].condProbTbl;
			//changed!
			//for (i = 0; i < (NUM_OF_TEMP_STATES * NUM_OF_LIGHT_STATES); i++)
			for (i = 0; i < (NUM_OF_TEMP_STATES * NUM_OF_LIGHT_STATES) /2 ; i++)
			{
				k = i + ((NUM_OF_TEMP_STATES * NUM_OF_LIGHT_STATES) /2);
				for (j = 0; j < NUM_OF_MOTE_STATES; j ++)
				{
					tempCondProbTbl -> condProb[i][j] = recdMsg -> probability[k][j];
				}
			}

//-- copy
			
		}
		
		return msg;
	}
	
	event message_t* CondProbReceive.receive(message_t* msg, void* payload, uint8_t len)
	{
		uint8_t i, j, k;
		CondProbMsg * recdMsg = (CondProbMsg *) payload;
		struct CondProbTbl *tempCondProbTbl;
		
		if (recdMsg -> finalDestAddr == TOS_NODE_ID)
		{
			//call Leds.led0Toggle();
			
			tempCondProbTbl = sensorStates[0].condProbTbl;
			for (i = 0; i < (NUM_OF_TEMP_STATES * NUM_OF_LIGHT_STATES) /2 ; i++)
			{
				for (j = 0; j < NUM_OF_MOTE_STATES; j++)
				{
					tempCondProbTbl -> condProb[i][j] = recdMsg->probability[i][j];
				}
			}
			
			tempCondProbTbl = sensorStates[1].condProbTbl;
			for (i = 0; i < (NUM_OF_TEMP_STATES * NUM_OF_LIGHT_STATES); i++)
			{
				k = i + (NUM_OF_TEMP_STATES * NUM_OF_LIGHT_STATES /2);
				for (j = 0; j < NUM_OF_MOTE_STATES; j ++)
				{
					tempCondProbTbl -> condProb[i][j] = recdMsg -> probability[k][j];
				}
			}
		}
		else ///< forward the cond prob message along
		{
			condProbPkt = *recdMsg;
			post sendCondProbMsg();
		}
		return msg;
	}
	
	event void SensorTimer.fired()
	{
		tempMeasureCounter ++;
		lightMeasureCounter ++;
		
		/// if the packet is full
		if (sendEventMsgToBS == TRUE)
		{
			/// if the node is a BS then send data to PC, otherwise send data over radio  
			if (TOS_NODE_ID == 1)
			{
				post sendEventMsg();
			}
			else 
			{
				post sendEventRadioMsg();				
			}	
		}
		
		if (tempMeasureCounter == TEMP_MEASURE_TIMER)
		{
			tempMeasureCounter = 0;
			if (call TempRead.read() != SUCCESS)
			{
				reportProblem(); ///< Notification of sensor issues. :)
			}
		}
		
		if (lightMeasureCounter == LIGHT_MEASURE_TIMER)
		{
			lightMeasureCounter = 1; ///< idea being to synchronise temp and light measures.
			if (call LightRead.read() != SUCCESS)
			{
				reportProblem(); ///< Notification of sensor issues. :)
			}
		}
	}
	
	event void TempRead.readDone(error_t status, uint16_t data)
	{
		if ( (data >= FRIDGE_TEMP_THRESHOLD) && (sensorStates[TEMP_OUTSIDE].enabled == FALSE) )
		{
			/// The node is outside
			sensorStates[TEMP_FRIDGE].enabled = FALSE;
			sensorStates[TEMP_OUTSIDE].enabled = TRUE;
			changeMoteState();
			
			#ifdef LED_DEBUG
				call Leds.led0Toggle();
			#endif
			
		}
		else if ( (data < FRIDGE_TEMP_THRESHOLD) && (sensorStates[TEMP_FRIDGE].enabled == FALSE) )
		{
			/// the node is in the fridge
			sensorStates[TEMP_OUTSIDE].enabled = FALSE;
			sensorStates[TEMP_FRIDGE].enabled = TRUE;
			changeMoteState();
			
			#ifdef LED_DEBUG
				//call Leds.ledToggle();
			#endif
		}
	}
	
	event void LightRead.readDone(error_t status, uint16_t data)
	{
		/// The node receives light like room light
		if ( (data >= LIGHT_OFF_THRESHOLD) && (data< LIGHT_BRIGHT_THRESHOLD) && (lightState != LIGHT_ROOM) )
		{
			lightState = LIGHT_ROOM;
			changeMoteState();
			
			#ifdef LED_DEBUG
				call Leds.led1Toggle();
			#endif
		}
		/// the node is in darkness
		else if ( (data < LIGHT_OFF_THRESHOLD) && (lightState != LIGHT_OFF) )
		{
			lightState = LIGHT_OFF;
			changeMoteState();
			
			#ifdef LED_DEBUG
				call Leds.led1Toggle();
			#endif
		}
		else if ( ( data > LIGHT_BRIGHT_THRESHOLD) && (lightState != LIGHT_BRIGHT) )
		{
			lightState = LIGHT_BRIGHT;
			changeMoteState();
			
			#ifdef LED_DEBUG
				call Leds.led1Toggle();
			#endif	
		}
	}
	
}

