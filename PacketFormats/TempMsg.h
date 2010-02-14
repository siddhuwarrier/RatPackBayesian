#ifndef TEMPMSG_H
#define TEMPMSG_H
#include "../headers/BayesMoteApp.h"

typedef nx_struct TempMsg
{
	nx_uint16_t finalDestAddr;
	nx_int16_t temperature[NUM_OF_TEMP_READINGS];
	nx_uint16_t timestamp[NUM_OF_TEMP_READINGS];
}TempMsg;
enum
{
	AM_TEMPMSG=12
};
#endif
