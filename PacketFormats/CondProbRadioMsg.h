#ifndef CONDPROBRADIOMSG_H
#define CONDPROBRADIOMSG_H
#include "../headers/BayesMoteApp.h"

typedef nx_struct CondProbRadioMsg
{
	nx_uint8_t finalDestAddr;
	nx_uint8_t probability[NUM_OF_TEMP_STATES*NUM_OF_LIGHT_STATES][NUM_OF_MOTE_STATES];
}__attribute__ ((packed)) CondProbRadioMsg;

enum
{
	AM_CONDPROBRADIOMSG=13
};
#endif
