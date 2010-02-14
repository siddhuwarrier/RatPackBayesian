#ifndef BAYESMOTEAPP_H
#define BAYESMOTEAPP_H

enum
{
	TIMER_TICK = 1000,
 	TEMP_MEASURE_TIMER = 2,
  	LIGHT_MEASURE_TIMER = 3,
	NUM_OF_TEMP_READINGS = 5,
 	TEMPERATURE_TYPE = 1,
  	LIGHT_TYPE = 2,
	NUM_OF_MOTE_STATES = 5,
 	NUM_OF_LIGHT_STATES = 3,
  	NUM_OF_TEMP_STATES = 2,
  	/// Temperature states
  	TEMP_FRIDGE = 0, ///< temp < 22 
   	TEMP_OUTSIDE = 1, ///< temp >=22
    	FRIDGE_TEMP_THRESHOLD = 6160, ///< equivalent to 22 deg cel
    	
    	/// Light states
    	LIGHT_ROOM = 0, 	///< light room
     	LIGHT_BRIGHT = 1, ///< light outside (or maybe even fridge)
     	LIGHT_OFF = 2, ///< light off
      	LIGHT_OFF_THRESHOLD = 20, ///< below 20, there's no light, and above it, there is	
	LIGHT_BRIGHT_THRESHOLD = 300,
      
      	/// Mote states
      	MOTE_FRIDGE_CLOSED = 0, ///< in fridge, door closed (i.e., light off)
        MOTE_FRIDGE_OPEN = 1, ///< in fridge, door open (i.e., light on)
	MOTE_OUTSIDE_BRIGHT = 2, ///< outside, light really bright
 	MOTE_OUTSIDE_ROOM = 3, ///< outside, light like in a room
 	MOTE_OUTSIDE_OFF = 4, ///< outside, light off
			
	NUM_OF_EVENTS_IN_PACKET = 1 ///< when num of events goes beyond NUM_OF_EVENTS_IN_PACKET, send message
};

struct SensorState
{
	uint8_t stateName:1;
	uint8_t enabled:1; 
	/// add children here
	struct CondProbTbl *condProbTbl;
}__attribute__((packed));

struct CondProbTbl
{
	uint8_t condProb[NUM_OF_LIGHT_STATES][NUM_OF_MOTE_STATES];
};
	
#endif

