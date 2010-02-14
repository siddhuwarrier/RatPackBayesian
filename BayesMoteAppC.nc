#include "PacketFormats/EventMsg.h"
#include "PacketFormats/CondProbMsg.h"
#include "PacketFormats/TempMsg.h"
#include "PacketFormats/EventRadioMsg.h"

configuration BayesMoteAppC
{
}

implementation
{
	components MainC, BayesMoteC as App, LedsC, ActiveMessageC, SerialActiveMessageC;
	components new TimerMilliC() as SensorTimer;
	
	/*components new AMSenderC(AM_EVENTMSG) as AMEventSenderC;
	components new AMReceiverC(AM_EVENTMSG) as AMEventReceiverC;*/
	
	components new AMSenderC(AM_TEMPMSG) as AMCondProbSenderC;
	components new AMReceiverC(AM_TEMPMSG) as AMCondProbRadioReceiverC;
	
	components new AMReceiverC(AM_EVENTRADIOMSG) as AMEventRadioReceiverC;
	
	
	components new SerialAMSenderC(AM_EVENTMSG) as AMEventSenderC;
	
	// !!
	components new AMSenderC(AM_EVENTRADIOMSG) as AMEventRadioSenderC;	
		
	/// Sensor components
	components new SensirionSht11C() as TempSensor; 
	components new HamamatsuS10871TsrC() as LightSensor;
	
	App.AMControl -> ActiveMessageC;
	App.AMSerialControl -> SerialActiveMessageC;
	App -> MainC.Boot;
	App.SensorTimer -> SensorTimer;
	App.Leds -> LedsC;
	
	// App.AMEventSend -> AMEventSenderC.AMSend;
	App.AMCondProbSend -> AMCondProbSenderC.AMSend;
	App.CondProbPacket -> AMCondProbSenderC;
	App.AMCondProbPacket -> AMCondProbSenderC;
	//App.Packet-> AMEventSenderC;
	//App.AMPacket-> AMEventSenderC;
	//App.Packet-> AMCondProbSenderC;
	//App.AMPacket-> AMCondProbSenderC;
	App.CondProbRadioReceive->AMCondProbRadioReceiverC;
	
		
	App.AMEventSend -> AMEventSenderC.AMSend;
	App.EventPacket-> AMEventSenderC;
	App.AMEventPacket-> AMEventSenderC;
	
	// App.EventReceive->AMEventReceiverC.Receive;
	App.CondProbReceive->SerialActiveMessageC.Receive[AM_CONDPROBMSG];
	// App.CondProbRadioReceive->ActiveMessageC.Receive[AM_CONDPROBMSG];
	
	App.TempRead -> TempSensor.Temperature;
	App.LightRead -> LightSensor.Read;
	
	// !!
	App.EventRadioReceive -> AMEventRadioReceiverC;
	App.AMEventRadioSend -> AMEventRadioSenderC.AMSend;
	App.EventRadioPacket-> AMEventRadioSenderC;
	App.AMEventRadioPacket-> AMEventRadioSenderC;	
	
	
}
