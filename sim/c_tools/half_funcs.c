#include "half_funcs.h"
unsigned short half_fp_gen(unsigned int RANDMAX)
{
    float randnum,cmpnum;
    unsigned int *p,temp,sign,var;
    unsigned short tempo;
    int exp;
    float sgnseed,randseed,sizeseed;
    if(rand()%2==0)sgnseed=1;
    else sgnseed=-1;
    sizeseed=rand()/(float)RAND_MAX*RANDMAX;
    randseed=rand()/(float)RAND_MAX*sizeseed;
    randnum=sgnseed*randseed;
    //p=&racdndnum;
    //*p=*p&0xffffe000;//pre-clipping test
    tempo=float2half(randnum);
    cmpnum=half2float(tempo);
    printf("#randnum=%f returned num=%f,clipping err=%f\n",randnum,cmpnum,randnum-cmpnum);
    return tempo;

}
float half_clip(float in)
{
    int *p;
    *p=*p&0xffffe000;
    return in;

}
unsigned short float2half(float in)
{
    unsigned int *p,temp,sign,var;
    unsigned char exp;
    
    p=&in;
    temp=*p;
    var=(temp&0x007fe000)>>13;
    sign=(temp&0x80000000)>>31;
    exp=((temp&0x7f800000)>>23)-127+15;
    printf("var_orig=%x,exp_orig=%i\n",temp&0x0007ffff,((temp&0x7f800000)>>23));
    printf("var=%x,sign=%i,exp=%i\n",var,sign,((char)(exp&0x1f)));
    return  var+(sign<<15)+(((exp)&0x1f)<<10);
} 
float half2float(unsigned short in)
{
    float *p;
    unsigned int binout=0,var,sign;
    unsigned char exp;
    p=&binout;
    var=(in&0x03ff)<<13;
    sign=(in&0x8000)>>15;
    exp=((in&0x7c00)>>10)-15+127;
    printf("var=%i,sign=%i,exp=%i\n",var,sign,exp);
    binout=var+(sign<<31)+(exp<<23);
    return *p;
}
void half_struct(char *p,unsigned short in)
{
    unsigned int binout=0,var,sign;
    char exp;
    var=(in&0x03ff);
    sign=(in&0x8000)>>15;
    exp=((in&0x7c00)>>10)-15;
    sprintf(p,"DATA=%x,num=%f,sign=%i,exp=%i,var=%x\n",in,half2float(in),sign,exp,var);

}