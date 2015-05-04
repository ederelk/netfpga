#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
unsigned long long timestamp;
unsigned long sec;
unsigned long nsec;
timestamp = 0x00000001fffffffe;
 sec=(unsigned long)((timestamp>>32)&0xffffffff);
 nsec=(unsigned long)(((timestamp&0xffffffff)*1000000000)>>32);
 
 printf("%010x.%010x\n",sec,nsec);
 return 0;
}
