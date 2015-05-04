#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>


int main (int argc, char **argv)
{
     if(argc != 2)
     {	
        printf("usage: %s \n\tplease, insert the result file from 'ntptime' command\n", argv[0]);
        return -1;
     }

     FILE * f_in = NULL;
     char riga_in[2048];
     char *punt;
     char *call_1 = "regwrite 0x2001214 ";
     char *call_2 = "regwrite 0x2001210 ";
     char *merge;
     int size;
     int size_command;
     int i;

     f_in=fopen(argv[1],"r");

     if (f_in==NULL)
     {
        printf("Error: it is impossible to open the file %s\n", argv[1]);
        return 1;
     }


     fgets(riga_in, 2048, f_in);
     punt=(char*)strstr(riga_in, "(ERROR)");
     if (punt!=NULL){
        printf("Error: it is impossible to obtain the timing from the NTP server\n");
        return 1;   
     }
     else{
        fgets(riga_in, 2048, f_in);
        punt=(char*)strstr(riga_in, "time ");
        punt+=5;
        strtok(punt, ". ");
        size = strlen(call_1)+1;
        for(i=0; i<2; i++){
           size_command = size + strlen(punt)+1;
           merge=(char*)malloc (sizeof(char)*size_command);
           if(i==0)
              strcpy(merge,call_1);
           else
              strcpy(merge,call_2);
           strcat(merge,"0x");
           strcat(merge,punt);
           //printf("%s\n", merge);
           system(merge);   
           punt=strtok(NULL, ". ");
        } 
     }
return 0;
}
  
