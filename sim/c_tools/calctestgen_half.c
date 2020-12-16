//FPU16 TEST CASE GENERATOR
//FADD/FSUB/FMUL/FDIV 
#include  <stdio.h>
#include  <stdlib.h>
#include "half_funcs.h"
#include "test_write.h"
#define RANDMAX 65535
int main(int argc,char * argv[])
{
    
    int i,length;
    unsigned int x,*op1,*op2,*datao,*dataconv;
    float op1_calc,op2_calc,datao_calc;
    char path[255];
    FILE *fp;
    //printf("%i,%s,%i \n",argc,*argv,argv[2]);
    if(argc==4)
    {
        printf("OK\n");
        sscanf(argv[2],"%d",&length);//acquire mem and allocate mem
        op1=malloc(length*4);
        op2=malloc(length*4);
        datao=malloc(length*4);
        for(i=0;i<length;i++)//calc source gen
        {
            op1[i]=half_fp_gen(RANDMAX);
            op2[i]=half_fp_gen(RANDMAX);
        }
        if(strcmp(argv[1],"-a")==0)
        {
            for(i=0;i<length;i++)
            {
                op1_calc=half2float((unsigned short)op1[i]);
                op2_calc=half2float((unsigned short)op2[i]);
                datao_calc=op1_calc+op2_calc;
                datao[i]=(unsigned int)float2half(datao_calc);
            }
        }
        else if(strcmp(argv[1],"-s")==0)
        {
            for(i=0;i<length;i++)
            {
                op1_calc=half2float((unsigned short)op1[i]);
                op2_calc=half2float((unsigned short)op2[i]);
                datao_calc=op1_calc-op2_calc;
                datao[i]=(unsigned int)float2half(datao_calc);
            }
            
        }
        else if(strcmp(argv[1],"-m")==0)
        {
            for(i=0;i<length;i++)
            {
                op1_calc=half2float((unsigned short)op1[i]);
                op2_calc=half2float((unsigned short)op2[i]);
                datao_calc=op1_calc*op2_calc;
                datao[i]=(unsigned int)float2half(datao_calc);
            }
        }
        else if(strcmp(argv[1],"-d")==0)
        {
            for(i=0;i<length;i++)
            {
                op1_calc=half2float((unsigned short)op1[i]);
                op2_calc=half2float((unsigned short)op2[i]);
                datao_calc=op1_calc/op2_calc;
                datao[i]=(unsigned int)float2half(datao_calc);
            }
        }
        else if(strcmp(argv[1],"-gq")==0)
        {
            for(i=0;i<length;i++)
            {
                op1_calc=half2float((unsigned short)op1[i]);
                op2_calc=half2float((unsigned short)op2[i]);
                datao[i]=(op1_calc>=op2_calc);
            }
        }
        else if(strcmp(argv[1],"-lt")==0)
        {
            for(i=0;i<length;i++)
            {
                op1_calc=half2float((unsigned short)op1[i]);
                op2_calc=half2float((unsigned short)op2[i]);
                datao[i]=(op1_calc<op2_calc);
            }
        }
        else if(strcmp(argv[1],"-eq")==0)
        {
            for(i=0;i<length;i++)
            {
                op1_calc=half2float((unsigned short)op1[i]);
                op2_calc=half2float((unsigned short)op2[i]);
                datao[i]=(op1_calc==op2_calc);
            }
        }
        else if(strcmp(argv[1],"-nq")==0)
        {
            for(i=0;i<length;i++)
            {
                op1_calc=half2float((unsigned short)op1[i]);
                op2_calc=half2float((unsigned short)op2[i]);
                datao[i]=(op1_calc!=op2_calc);
            }
        }
        else 
        {
            printf("Argument Err!\n");
            return -1;
        }
        sprintf(path,"%s_a.hex",argv[3]);
        hex_write(path,op1,length,0);
        sprintf(path,"%s_b.hex",argv[3]);
        hex_write(path,op2,length,0);
        sprintf(path,"%s_o.hex",argv[3]);
        hex_write(path,datao,length,0);
    }
    else
    {
        printf("calctestgen_half -TYPE [LENGTH] /PATH/TO/[FILE]\n");
        printf("This tool will generate 3 HEX files under given filename\n");
        printf("\tExample: given name is mul_test, it will generate\n");
        printf("\tmul_test_a.hex,mul_test_b.hex,mul_test_o.hex\n");
        printf("\tCorresponding to OP1, OP2, DATAo\n");
        printf("-a for FADD output,\n -s for FSUB output,\n");
        printf(" -m for FMUL output,\n -d for FDIV output,\n"); 
        printf(" -gq for GREAT OR EQUAL output,\n -lt for LESS THAN output,\n"); 
        printf(" -eq for CMP EQUAL output,\n -nq for FDIV output\n");    
    }
    
    return 0;
}
