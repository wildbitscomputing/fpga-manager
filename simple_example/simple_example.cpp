#include <stdio.h>
#include <cstdint>
//
#include "f_util.h"
#include "ff.h"
#include "pico/stdlib.h"
#include "rtc.h"
#include "hardware/uart.h"
#include "hardware/gpio.h"
#include "hardware/xosc.h"
//
#include "hw_config.h"
#include "hardware/clocks.h"


// datasheet for information on which other pins can be used.
#define UART_ID uart1
#define BAUD_RATE 115200
#define DATA_BITS 8
#define STOP_BITS 1
#define PARITY    UART_PARITY_NONE

#define UART_TX_PIN 24
#define UART_RX_PIN 25

#define SPI_SUPER_MISO_i    0   // SPI0
#define SPI_SUPER_CSn_i     1   // SPI0
#define SPI_SUPER_SCLK_i    2   // SPI0
#define SPI_SUPER_MOSI_o    3   // SPI0
#define FPGA_CONFIG_PRG     4   // Output - Pulse to begin Sequence
#define FPGA_SYSTEM_RSTn    5   // Output 
#define FPGA_CONFIG_CCLK    6   // Output 
#define FPGA_CONFIG_INITn   7   // Input
// Output 
#define FPGA_BUS_D0         8
#define FPGA_BUS_D1         9
#define FPGA_BUS_D2         10
#define FPGA_BUS_D3         11
#define FPGA_BUS_D4         12
#define FPGA_BUS_D5         13
#define FPGA_BUS_D6         14
#define FPGA_BUS_D7         15
// Input
#define F256K2_CONTEXT_SW0  16
#define F256K2_CONTEXT_SW1  17
#define SPI_SD_SD1          21  // Not used now
#define SPI_SD_SD2          22  // Not used Now

// UART Definition
#define COM_TX_PIN          24  // UART1
#define COM_RX_PIN          25  // UART1
#define ADC0                26
#define ADC1                27
#define ADC2                28
#define ADC3                29

#define FIXED_FILE_SIZE   9730652
#define BUFFER_SIZE       32768

// Prototpyes
void f256k2_context_man_init_io( void );
void f256k2_Set_FPGA_Data_Port( unsigned char Value );
void f256k2_Init_Prg_FPGA( void );
void f256k2_Prg_Block_FPG( unsigned char * Buffer, unsigned int Size);
//void f256k2_Prg_Block_FPG( void );

unsigned char Buffer0[BUFFER_SIZE];
//unsigned char Buffer1[BUFFER_SIZE];

// See FatFs - Generic FAT Filesystem Module, "Application Interface",
    // http://elm-chan.org/fsw/ff/00index_e.html

unsigned char Sw_Choice;
//FSIZE_t File_Size;
   
int main() {
    unsigned int i,j,k;
    unsigned int BlockCount;
    unsigned int ActiveBuffer;
    FRESULT ReadStat;
    unsigned int MailBox;
    //unsigned int Block32k;
    //unsigned int LastBlockBytes;
    FIL fil;
    sd_card_t *pSD = sd_get_by_num(0);
    //set_sys_clock_khz(266000, true);
    stdio_init_all();
    xosc_init(); // #define PICO_XOSC_STARTUP_DELAY_MULTIPLIER 64
    time_init();
    //stdio_uart_init_full (uart1, BAUD_RATE, UART_TX_PIN, -1);       // Setup STDIO to Terminal UART (to be removed later)
    
    f256k2_context_man_init_io();    // Go Init all the GPIOs I will need

    // Let's Mount the SDCard First
    FRESULT fr = f_mount(&pSD->fatfs, pSD->pcName, 1);
    if (FR_OK != fr) 
        panic("f_mount error: %s (%d)\n", FRESULT_str(fr), fr);

    i = (gpio_get_all() & 0x00030000) >> 16;    // Read the 2 bits from DipSwitch to know which Load with need to get in there!
    Sw_Choice = (i & 0x03); // Save Value for later use 
    printf("DipSwitches is set to: %d\n", Sw_Choice);  

    switch( Sw_Choice ) {

        case 0: 
            printf("Opening CNTX1/CFP95600C.bin\n");
            fr = f_open(&fil, "CNTX1/CFP95600C.bin", FA_READ); 
        break;

        case 1:
            printf("Opening CNTX2/CFP95616E.bin\n");
            fr = f_open(&fil, "CNTX2/CFP95616E.bin", FA_READ);  
        break;

        case 2:
            fr = f_open(&fil, "CNTX3/f256k2t9.bin", FA_READ);
        break;

        case 3:
            fr = f_open(&fil, "CNTX4/foenix138.bin", FA_READ);
        break;

        default: 
            fr = f_open(&fil, "CNTX4/foenix138.bin", FA_READ);
        break;

    }      

 

    if ( FR_OK == fr) {
        printf("All is Good, File is open!\n");
        //File_Size = f_size(&fil);   // Okay let's get the Size
        //printf("The File Size is: %X\n", File_Size);
        
        //multicore_launch_core1(f256k2_Prg_Block_FPG);    // Get the Second Core Going
       
        //printf("The Core1 is Started and the Code is: %X\n", MailBox);
        f256k2_Init_Prg_FPGA();
        k = 0;
        BlockCount = 0;
        do {
            f_lseek(&fil, k);
            FRESULT ReadStat = f_read (&fil, Buffer0, BUFFER_SIZE, &j);      // J = How many were read
            k = k + j;  // 
            i = BUFFER_SIZE - j; 
            //printf("Block #: %d Byte Read: %d %d\n", BlockCount++, j);
            f256k2_Prg_Block_FPG(Buffer0, j);
        }
        while ( i == 0);    // Process Blocks of 32K first
        
        f256k2_Prg_Block_FPG(Buffer0, i);       // Last Block
        //gpio_put( FPGA_CONFIG_CSn,1);          // Bring DOwn the ChipSelect
        gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_OUT);     
        for (k = 0; k < 100; k++){
            gpio_put( FPGA_CONFIG_CCLK, 0);        // Bring Down the Clock   
            gpio_put( FPGA_CONFIG_CCLK, 1);        // Bring Up the Clock
        }        
        gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_IN);        
    }
    else {
        printf("File Not Found!\n");


    }
    set_sys_clock_khz(133000, true); // 328us    
    printf("We are Done...\n");

    fr = f_close(&fil);



    f_unmount(pSD->pcName);


    
    for (;;);
}

// This could have been done with a loop but for the sake of simplicity, I am numerating
void f256k2_context_man_init_io( void ) {
    // GPIO Init
    gpio_init(FPGA_CONFIG_PRG);     // Output - Pulse to begin Sequence
    //gpio_init(FPGA_CONFIG_DONE);    // Input   
    gpio_init(FPGA_CONFIG_CCLK);    // Output 
    gpio_init(FPGA_CONFIG_INITn);   // Input
    gpio_init(FPGA_SYSTEM_RSTn);   // I/O 
    //gpio_init(FPGA_CONFIG_CSn);     // Output

    gpio_init(FPGA_BUS_D0);         // Output
    gpio_init(FPGA_BUS_D1);         // Output
    gpio_init(FPGA_BUS_D2);         // Output
    gpio_init(FPGA_BUS_D3);         // Output
    gpio_init(FPGA_BUS_D4);         // Output
    gpio_init(FPGA_BUS_D5);         // Output
    gpio_init(FPGA_BUS_D6);         // Output
    gpio_init(FPGA_BUS_D7);         // Output

    gpio_init(SPI_SD_SD1);          // Output (Not used right now)
    gpio_init(SPI_SD_SD2);          // Output (Not used right now)

    gpio_init(F256K2_CONTEXT_SW0);  // Input
    gpio_init(F256K2_CONTEXT_SW1);  // Input  
    // GPIOs Direction
    gpio_set_dir(FPGA_CONFIG_PRG, GPIO_OUT);
    //gpio_set_dir(FPGA_CONFIG_DONE, GPIO_IN);
    gpio_set_dir(FPGA_CONFIG_CCLK, GPIO_OUT);
    gpio_set_dir(FPGA_CONFIG_INITn, GPIO_IN);
    gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_IN);    
    //gpio_set_dir(FPGA_CONFIG_CSn, GPIO_OUT);

    gpio_set_dir(SPI_SD_SD1, GPIO_OUT);
    gpio_set_dir(SPI_SD_SD2, GPIO_OUT);

    gpio_set_dir(FPGA_BUS_D0, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D1, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D2, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D3, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D4, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D5, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D6, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D7, GPIO_OUT);

    gpio_set_dir(F256K2_CONTEXT_SW0, GPIO_IN);
    gpio_set_dir(F256K2_CONTEXT_SW1, GPIO_IN);

    gpio_put( FPGA_CONFIG_PRG, 1);
    gpio_put( FPGA_CONFIG_CCLK, 1);
    gpio_put( FPGA_SYSTEM_RSTn, 0); // Set the Output to 0, but we are going to switch between Tri-State(Read) and OUtput (0)

    gpio_put( SPI_SD_SD1, 1);
    gpio_put( SPI_SD_SD2, 1);
    
    //gpio_put( FPGA_CONFIG_CSn, 1);

    //    gpio_pull_up( xxxx ); // Just in Case I might need this
}

// This is to Set the DataPort GPIO8--GPIO15
void f256k2_Set_FPGA_Data_Port( unsigned char Value ) {
    unsigned int Val=0;
    Val = Val | (Value << 8);   // Position the Value for offset Bit 8 to 15 
    gpio_put_masked	( 0x0000FF00, Val); 
}


void f256k2_Init_Prg_FPGA( void ) {
    unsigned int i;

    // Bring Down Program
    gpio_put( FPGA_CONFIG_PRG, 0);
    printf("Programn is Low\n");
    do {
        gpio_put( FPGA_CONFIG_CCLK, 0);        // Bring Down the Clock   
        gpio_put( FPGA_CONFIG_CCLK, 1);        // Bring Up the Clock        
    }
    while ( gpio_get(FPGA_CONFIG_INITn));       // Wait Till it gets down
    printf("Initn is Low\n");
    gpio_put( FPGA_CONFIG_PRG,1);
    printf("Programn is High\n");
    do {
        gpio_put( FPGA_CONFIG_CCLK, 0);        // Bring Down the Clock   
        gpio_put( FPGA_CONFIG_CCLK, 1);        // Bring Up the Clock        
    }
    while ( gpio_get(FPGA_CONFIG_INITn) == 0);       // Wait Till it gets up
    printf("Initn is Hi\n");
    gpio_put( FPGA_CONFIG_CCLK, 0);        // Bring Down the Clock   
    gpio_put( FPGA_CONFIG_CCLK, 1);        // Bring Up the Clock    
    //gpio_put( FPGA_CONFIG_CSn, 0);          // Bring DOwn the ChipSelect    


}

void f256k2_Prg_Block_FPG( unsigned char * Buffer, unsigned int Size) {
    unsigned int i;
    for ( i = 0; i < Size; i++) {
        f256k2_Set_FPGA_Data_Port( Buffer[i] );        
        gpio_put( FPGA_CONFIG_CCLK, 0);        // Bring Down the Write Strobe        
        gpio_put( FPGA_CONFIG_CCLK, 1);        // Bring Down the Write Strobe   
    }

}


/*
static void gpio_put_masked	(	uint32_t	mask,
uint32_t	value )
inlinestatic
Drive GPIO high/low depending on parameters.

Parameters
mask	Bitmask of GPIO values to change, as bits 0-29
value	Value to set
For each 1 bit in mask, drive that pin to the value given by corresponding bit in value, leaving other pins unchanged. Since this uses the TOGL alias, it is concurrency-safe with e.g. an IRQ bashing different pins from the same core.
*/