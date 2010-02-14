#ifndef CONDPROBMSG_H
#define CONDPROBMSG_H
#include "../headers/BayesMoteApp.h"

typedef nx_struct CondProbMsg
{
	nx_uint8_t finalDestAddr;
	nx_uint8_t probability[NUM_OF_TEMP_STATES*NUM_OF_LIGHT_STATES][NUM_OF_MOTE_STATES];
}__attribute__ ((packed)) CondProbMsg;

enum
{
	AM_CONDPROBMSG=11
};
#endif
