#include "test_write.h"
int hex_write(char *path,unsigned int *datain,unsigned int datalength,unsigned int startaddr)
{
    FILE *fp;
    int i;
    fp=fopen(path,"w");
    if(fp==NULL)
    {
        printf("File Access ERROR!EXIT!\n");
        return -1;
    }
    fprintf(fp, "@%d\n",startaddr);
    for(i=0;i<datalength;i++)
    {
        fprintf(fp, " %x\n",datain[i]);
    }
        fclose(fp);
        return 0;
}
int COE_write(char *path,unsigned int *datain,unsigned int datalength)
{
    FILE *fp;
    int i;
    fp=fopen(path,"w");
    if(fp==NULL)
    {
        printf("File Access ERROR!EXIT!\n");
        return -1;
    }
    fprintf(fp, "MEMORY_INITIALIZATION_RADIX=10;\n");
    for(i=0;i<datalength;i++)
    {
        fprintf(fp, "\t %d,\n",datain[i]);
    }
    fprintf(fp, ";\n");
    fclose(fp);
    return 0;
}
int mif_write(char *path,unsigned short bitwidth,unsigned int *datain,unsigned int datalength,unsigned int startaddr)
{
    FILE *fp;
    int i;
    fp=fopen(path,"w");
    if(fp==NULL)
    {
        printf("File Access ERROR!EXIT!\n");
        return -1;
    }
    fprintf(fp, "WIDTH=%d;\n",bitwidth);
    fprintf(fp, "DEPTH=%d;\n",datalength);
    fprintf(fp, "ADDRESS_RADIX=UNS;\n");
    fprintf(fp, "DATA_RADIX=HEX;\n\n");
    fprintf(fp, "CONTENT BEGIN\n");
    for(i=startaddr;i<startaddr+datalength;i++)
    {
        fprintf(fp, "\t%d : %x;\n",i,datain[i]);
    }
    fprintf(fp, "END;\n");
    fclose(fp);
    return 0;
}

