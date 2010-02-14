#ifndef EVENTMSG_H
#define EVENTMSG_H
#include "../headers/BayesMoteApp.h"

enum
{
	AM_EVENTMSG=10
};

typedef nx_struct EventMsg
{
	nx_int8_t srcAddr;
	nx_int8_t moteEvent[NUM_OF_EVENTS_IN_PACKET];
	nx_uint8_t prob[NUM_OF_EVENTS_IN_PACKET];
}__attribute__((packed)) EventMsg;
#endif
