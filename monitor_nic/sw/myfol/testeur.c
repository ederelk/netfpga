#include <stdio.h>
#include <stdlib.h>


int main(int argc, char *argv[])
{
unsigned long long timestamp64;
unsigned long long mtimestamp64;
unsigned long sec;
unsigned long nsec;
unsigned long msec;
unsigned long mnsec;
timestamp64 = 0x00000001ffffffffULL;
msec =  0x00000001;
mnsec = 0xffffffff;
mtimestamp64 = msec;
mtimestamp64 = mtimestamp64 << 32;
mtimestamp64 = mtimestamp64 + mnsec;
printf("%llx \n",timestamp64);
printf("%llx \n",mtimestamp64);
 sec=(unsigned long)((timestamp64>>32)&0xffffffff);
 nsec=(unsigned long)(((timestamp64&0xffffffff)*1000000000)>>32);
msec=(unsigned long)((mtimestamp64>>32)&0xffffffff);
 mnsec=(unsigned long)(((mtimestamp64&0xffffffff)*1000000000)>>32);
 printf("%lx.%lx\n",sec,nsec);
 printf("%1u.%1u\n",msec,mnsec);
 return 0;
}
