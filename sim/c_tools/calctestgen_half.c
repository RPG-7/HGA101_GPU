//FPU16 TEST CASE GENERATOR
//FADD/FSUB/FMUL/FDIV 
#include  <stdio.h>
#include  <stdlib.h>
#include "half_funcs.h"
#include "test_write.h"
#define RANDMAX 512
int main(int argc,char * argv[])
{
    int i,j,length;
    unsigned int x,*op1,*op2,*datao,*dataconv,length_o;
    float op1_calc,op2_calc,datao_calc;

    char path[255];
    FILE *fp;
    //printf("%i,%s,%i \n",argc,*argv,argv[2]);
    if(argc==4)
    {
        printf("OK\n");
        sscanf(argv[2],"%d",&length);//acquire mem and allocate mem
        length_o=length;
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
        else if(strcmp(argv[1],"-cmp")==0)
        {
            for(i=0;i<length;i++)
            {
                op1_calc=half2float((unsigned short)op1[i]);
                op2_calc=half2float((unsigned short)op2[i]);
                datao[i]=2*(op1_calc>op2_calc)+(op1_calc=op2_calc);
            }
        }
        else if(strcmp(argv[1],"-all")==0)
        {
            free(datao);
            datao=malloc(length*4*5);
            for(i=0;i<length;i++)
            {
                op1_calc=half2float((unsigned short)op1[i]);
                op2_calc=half2float((unsigned short)op2[i]);
                datao_calc=op1_calc+op2_calc;
                datao[i]=(unsigned int)float2half(datao_calc);
                datao_calc=op1_calc-op2_calc;
                datao[i+1*length]=(unsigned int)float2half(datao_calc);
                datao_calc=op1_calc*op2_calc;
                datao[i+2*length]=(unsigned int)float2half(datao_calc);
                datao_calc=op1_calc/op2_calc;
                datao[i+3*length]=(unsigned int)float2half(datao_calc);
                datao[i+4*length]=2*(op1_calc>op2_calc)+(op1_calc=op2_calc);
            }
            length_o=5*length;
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
        hex_write(path,datao,length_o,0);
        sprintf(path,"%s_testpattern.txt",argv[3]);
        fp=fopen(path,"w");
        if(fp==NULL)
        {
            printf("File Access ERROR!EXIT!\n");
            return -1;
        }
        for(i=0;i<length;i++)
        {   
            half_struct(&path[0],op1[i]);
            fprintf(fp, "OP1: %s",path);
            half_struct(&path[0],op2[i]);
            fprintf(fp, "OP2: %s",path);
            for(j=0;j<(length_o/length);j++)
            {
                half_struct(&path[0],datao[i+j*length]);
                fprintf(fp, "test%i: %s",j+1,path);
            }
        }
            fclose(fp);
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
        printf(" -cmp for FCMP output, bit0 is EQ, bit1 is GT\n");  
        printf(" -all for calc all outputs with same set of data\n");  
    }
    
    return 0;
}
