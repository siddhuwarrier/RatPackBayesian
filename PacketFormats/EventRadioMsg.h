#ifndef EVENTRADIOMSG_H
#define EVENTRADIOMSG_H
#include "../headers/BayesMoteApp.h"

typedef nx_struct EventRadioMsg
{
	nx_uint8_t srcAddr;
	nx_int8_t moteEvent[NUM_OF_EVENTS_IN_PACKET];
	nx_uint8_t prob[NUM_OF_EVENTS_IN_PACKET];
}__attribute__ ((packed)) EventRadioMsg;	
enum
{
	AM_EVENTRADIOMSG=14
};
#endif
