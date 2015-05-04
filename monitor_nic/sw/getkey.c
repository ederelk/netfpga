/* ****************************************************************************
 * $Id: regread.c 2267 2007-09-18 00:09:14Z grg $
 *
 * Module: regread.c
 * Project: NetFPGA 2 Register Access
 * Description: Reads a register
 *
 * Change history:
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <net/if.h>

#include "nf2.h"
#include "nf2util.h"

#define PATHLEN		80

#define DEFAULT_IFACE	"nf2c0"

/* Global vars */
static struct nf2device nf2;
//int new_id_flag = 0x2000008 ;
//int id_num = 0x200120c;
//int timestamp_high = 0x2001214;
//int timestamp_low = 0x2001210;

int id_num = 0x2001204 ;
int timestamp_high = 0x200120c;
int timestamp_low = 0x2001208;
/* Function declarations */
int main(int argc, char *argv[])
{
	 unsigned  tsp_h;
	 unsigned  tsp_l;
	unsigned  id,buffer;

	nf2.device_name = DEFAULT_IFACE;

	// Open the interface if possible
	if (check_iface(&nf2))
	{
		exit(1);
	}
	if (openDescriptor(&nf2))
	{
		exit(1);
	}
while(1){
	//readReg(&nf2, new_id_flag, &flag);
	
	//if(flag == 1){
	// FIXME: Perform the actual register read and print the value
	buffer = id;
	readReg(&nf2, id_num, &id); 
	readReg(&nf2, timestamp_high, &tsp_h);
	readReg(&nf2, timestamp_low, &tsp_l);
	if (buffer != id && id>0)
	printf("  %010u.%010u		%1u  \n",tsp_h,tsp_l,id);
	//printf("%x \n",id);	//usleep(9000);	//}	
}
closeDescriptor(&nf2);
	return 0;
}
