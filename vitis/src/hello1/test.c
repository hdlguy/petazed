
#include <stdlib.h>
#include "xil_printf.h"
#include "xparameters.h"

#define BRAM_SIZE (1 + XPAR_BRAM_0_HIGHADDR - XPAR_BRAM_0_BASEADDR) // bram size in bytes

#define DDR_BLOCK_SIZE (4*1024*1024)
uint32_t ddrptr[DDR_BLOCK_SIZE/4];


int main()
{

    uint32_t* bramptr = (uint32_t *)XPAR_BRAM_0_BASEADDR;

    xil_printf("\n\rHello!\n\r");

    // test bram
    xil_printf("bramptr = 0x%08x, BRAM_SIZE = 0x%04x\n\r", bramptr, BRAM_SIZE);
    srand(1);
    for (int i=0; i<BRAM_SIZE/4; i++) bramptr[i] = rand();
    uint32_t randval, readval;
    int errors=0;
    srand(1);
    for (int i=0; i<BRAM_SIZE/4; i++) {
    	randval = rand();
    	if (randval != bramptr[i]) errors++;
    }
    xil_printf("bram test: errors = %d\n\r", errors);
    

    // test ddr
    xil_printf("ddrptr = 0x%08x, DDR_BLOCK_SIZE = 0x%04x\n\r", ddrptr, DDR_BLOCK_SIZE);
    srand(1);
    for (int i=0; i<DDR_BLOCK_SIZE/4; i++) ddrptr[i] = rand();
    errors=0;
    srand(1);
    for (int i=0; i<DDR_BLOCK_SIZE/4; i++) {
    	randval = rand();
    	readval = ddrptr[i];
    	if (randval != readval) {
    		errors++;
    		xil_printf("%d: %08x  %08x\n\r", i, randval, readval);
    	}
    }
    xil_printf("ddr test: errors = %d\n\r", errors);
    
    xil_printf("testing complete\n\r");
    
    while(1);

    return 0;

}


