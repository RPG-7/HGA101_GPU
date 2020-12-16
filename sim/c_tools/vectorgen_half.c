//random half float number generator
#include  <stdio.h>
#include  <stdlib.h>
#include "half_funcs.h"
#define RANDMAX 65535
int main(int argc,char * argv[])
{
    
    int i,length;
    unsigned int x;
    FILE *fp;
    printf("%i,%s,%i \n",argc,*argv,argv[2]);
    if(argc>2)
    {
        printf("OK\n");
        sscanf(argv[2],"%d",&length);
        if(strcmp(argv[1],"-s")==0)
        {
            for(i=0;i<length;i++)
            {
                x=half_fp_gen(RANDMAX);
                printf("%x\n",x);
            }
        }
        else if(strcmp(argv[1],"-m")==0)
        {
            fp=fopen(argv[3],"w");
            if(fp==NULL)
            {
                printf("File Access ERROR!EXIT!\n");
                return -1;
            }
            fprintf(fp, "WIDTH=16;\n");
            fprintf(fp, "DEPTH=%d;\n",length);
            fprintf(fp, "ADDRESS_RADIX=UNS;\n");
            fprintf(fp, "DATA_RADIX=HEX;\n\n");
            fprintf(fp, "CONTENT BEGIN\n");
            for(i=0;i<length;i++)
            {
                x=half_fp_gen(RANDMAX);
                fprintf(fp, "\t%d : %x;\n",i,x);
            }
             fprintf(fp, "END;\n");
             fclose(fp);
        }
        else if(strcmp(argv[1],"-h")==0)
        {
            fp=fopen(argv[3],"w");
            if(fp==NULL)
            {
                printf("File Access ERROR!EXIT!\n");
                return -1;
            }
            fprintf(fp, "@00000000;\n");
            for(i=0;i<length;i++)
            {
                x=half_fp_gen(RANDMAX);
                fprintf(fp, "\t %x;\n",x);
            }
             fclose(fp);
        }
        else 
        {
            printf("Argument Err!\n");
            return -1;
        }
        
    }
    else
    {
        printf("vectorgen_TYPE -ARGUMENT [LENGTH] /PATH/TO/[FILE]\n");
        printf("\t-s for stdout output,\n\t -m for MIF file output,\n");
        printf("\t-h for HEX file output,\n");    
    }
    
    return 0;
}
