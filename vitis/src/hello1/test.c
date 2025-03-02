
#include <stdlib.h>
#include "xil_printf.h"
#include "xparameters.h"

#define BRAM_SIZE (1 + XPAR_BRAM_0_HIGHADDR - XPAR_BRAM_0_BASEADDR) // bram size in bytes


int main()
{

    uint32_t* bramptr = (uint32_t *)XPAR_BRAM_0_BASEADDR;

    xil_printf("Hello! bramptr = 0x%08x, BRAM_SIZE = 0x%04x\n\r", bramptr, BRAM_SIZE);

    srand(1);
    for (int i=0; i<BRAM_SIZE/4; i++) bramptr[i] = rand();

    uint32_t randval;
    int errors=0;
    for (int i=0; i<BRAM_SIZE/4; i++) {
    	randval = rand();
    	if (randval != bramptr[i]) errors++;
    }
    xil_printf("bram test: errors = %d", errors);

    return 0;

}

