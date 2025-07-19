
#include <stdlib.h>
#include "xil_printf.h"
#include "xparameters.h"

#define BRAM_SIZE (1 + XPAR_AXI_BRAM_CTRL_0_HIGHADDR - XPAR_AXI_BRAM_CTRL_0_BASEADDR) // bram size in bytes

#define DDR_BLOCK_SIZE (64*1024*1024)
uint32_t ddrptr[DDR_BLOCK_SIZE/4];

int main()
{
    uint32_t* bramptr = (uint32_t *)XPAR_AXI_BRAM_CTRL_0_BASEADDR;
    xil_printf("bramptr = 0x%08x, BRAM_SIZE = 0x%04x\n\r", bramptr, BRAM_SIZE);
    xil_printf("ddrptr = 0x%08x, DDR_BLOCK_SIZE = 0x%04x\n\r", ddrptr, DDR_BLOCK_SIZE);

    uint32_t whilecount=0;
    while(1) {

        xil_printf("\n\r%08d: Hello!\n\r", whilecount);

        // test bram
        srand(whilecount);
        for (int i=0; i<BRAM_SIZE/4; i++) bramptr[i] = rand();
        uint32_t randval, readval;
        int errors=0;
        srand(whilecount);
        for (int i=0; i<BRAM_SIZE/4; i++) {
            randval = rand();
            if (randval != bramptr[i]) errors++;
        }
        xil_printf("bram test: errors = %d\n\r", errors);
        

        // test ddr
        srand(whilecount);
        for (int i=0; i<DDR_BLOCK_SIZE/4; i++) ddrptr[i] = rand();
        errors=0;
        srand(whilecount);
        for (int i=0; i<DDR_BLOCK_SIZE/4; i++) {
            randval = rand();
            readval = ddrptr[i];
            if (randval != readval) {
                errors++;
                xil_printf("%d: %08x  %08x\n\r", i, randval, readval);
            }
        }
        xil_printf("ddr test: errors = %d\n\r", errors);

        //for(int i=0; i<1000000; i++);
        whilecount++;

    }
    
    xil_printf("testing complete\n\r");
    
    while(1);

    return 0;

}


