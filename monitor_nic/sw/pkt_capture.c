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
int end_counter =0;
unsigned int *ptr_one;
unsigned int i,memsize,numofrows;
/* Function declarations */

int main(int argc, char *argv[])
{
unsigned long long timestamp64;
unsigned long sec;
unsigned long nsec;
unsigned  tsp_h;
	 unsigned  tsp_l;
	unsigned  id,buffer;
unsigned j = 0;
unsigned priority ;
//sleep(60);
priority = nice(-20);
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
memsize = (1024*1024*3*sizeof(unsigned int ))/2;
numofrows = memsize/4;
i = 0;

 FILE * Output;
   
    
    
		ptr_one = (unsigned int *)malloc(memsize);
		if (ptr_one == 0)
		{
			printf("ERROR: Out of memory\n");
			return 1;
		}

  printf("The allocated memory is %d bytes\n", (memsize));
  printf("The number of packet that can be captured is %d \n",numofrows);
  printf("The pointer start address is %x \n", ptr_one);
  printf("The priority of this process is %d \n ",priority);
  while(i<numofrows)
  {
 	 buffer = id;
	readReg(&nf2, id_num, &id); 
	readReg(&nf2, timestamp_high, &tsp_h);
	readReg(&nf2, timestamp_low, &tsp_l);
		if (buffer != id ){
		end_counter = 0;
		*ptr_one = tsp_h;
		i+=1;  
	      	ptr_one +=1;
	      	*ptr_one = tsp_l;
		i+=1;  
	      	ptr_one +=1;
	      	*ptr_one = id;
		i+=1;  
	      	ptr_one +=1;
		//printf("  %010u.%010u		%1u  \n",tsp_h,tsp_l,id);
		//printf("%x \n",id);	//usleep(9000);	//}	
		}else{
		end_counter +=1;
		if(end_counter == 2000000){

		  ptr_one -=i;
		  j = i; 
		  i=0;
		   Output = fopen("data.txt", "w");
		   
		  while(i<j)
		  {
		              //  printf("%x=========>%x \n", ptr_one,*ptr_one);
		              timestamp64 = (unsigned long)*ptr_one;
		              timestamp64 = timestamp64 << 32;
		 // fprintf(Output ,"%010u.",*ptr_one);
		  ptr_one +=1;
		  i+=1;
		    //fprintf(Output ,"%010u",*ptr_one);
		    
		    timestamp64 = timestamp64 + (unsigned long)(*ptr_one);
		     sec=(unsigned long)((timestamp64>>32)&0xffffffff);
 		     nsec=(unsigned long)(((timestamp64&0xffffffff)*1000000000)>>32);
		  fprintf(Output,"%1u.%1u",sec,nsec);
		    
		  ptr_one +=1;
		  i+=1;
		    fprintf(Output ,"		%1u\n",*ptr_one);
		  ptr_one +=1;
		  i+=1;
		             }
		             
		     closeDescriptor(&nf2);
		fclose(Output);
		     ptr_one -=i;         
		  free(ptr_one);
		  printf("DONE!!!!!!!!!!!!!!!!! \n");
		  	return 0;
		}
		}
		      
      
      
      
      
      
      
 }    
  //system("PAUSE");	
 return 0;
}
