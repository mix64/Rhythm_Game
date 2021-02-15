//-----------------------------------------------------------------------------
// Title       : サウンド回路のテストプログラム（SDカード内のwavファイルを読み込んで出力する）
// Project     : サウンド回路
// Filename    : snd_test_sd.c
//-----------------------------------------------------------------------------
// Description :
//
//-----------------------------------------------------------------------------
// Revisions   :
// Date        Version  Author        Description
// 2014/07/28  1.00     M.Kobayashi   Created
// 2017/12/18  1.10     M.Kobayashi   SDK純正のFatFSに対応
//-----------------------------------------------------------------------------

#include <stdio.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "cojt.h"
#include "ff.h"

#include "snd.h"

#define MEM ((volatile unsigned char *) 0x20000000)
#define BLKSIZE 4096

#define BGM_ADDR (*(volatile unsigned int *) (XPAR_REGBUS_0_BASEADDR + 0x3000))
#define BGM_SIZE (*(volatile unsigned int *) (XPAR_REGBUS_0_BASEADDR + 0x3004))
#define SE_ADDR (*(volatile unsigned int *) (XPAR_REGBUS_0_BASEADDR + 0x3008))
#define SE_SIZE (*(volatile unsigned int *) (XPAR_REGBUS_0_BASEADDR + 0x300C))
#define SND_VOL (*(volatile unsigned int *) (XPAR_REGBUS_0_BASEADDR + 0x3010))
#define SND_CTRL (*(volatile unsigned int *) (XPAR_REGBUS_0_BASEADDR + 0x3014))

#define SND_RST 0x00000001
#define SND_BGM_PLAY 0x00000002
#define SND_SE_PLAY 0x00000006

#define BGM_FILE "bgm.wav"
#define SE_FILE "se.wav"

#define BGM_BASE 0x1000000
#define SE_BASE  0x3000000

/* SDカードのファイルを読み込みVRAMに書き込む */
int readfile(unsigned int base, char *filename) {
    int i, cnt=0;
    UINT num;
    FRESULT fr;
    FATFS FatFs;
    FIL Fil;
    unsigned char buff[BLKSIZE+100];

    xil_printf("Reading '%s' on the SD Card.\n", filename);
    f_mount(&FatFs, "", 0);
    fr=f_open(&Fil, filename, FA_READ);
    if ( fr ) {
        xil_printf("Open Error!\n");
    }
    while(1) {
        f_read(&Fil, buff, BLKSIZE, &num);
        for ( i=0; i<num; i++ ) {
            MEM[base+cnt+i] = buff[i];
        }
        cnt += BLKSIZE;
        if (num<BLKSIZE) {
            break;
        }
    }
    f_close(&Fil);
    Xil_DCacheFlush();

    return ((MEM[base+43]<<24) | (MEM[base+42]<<16) | (MEM[base+41]<<8) | MEM[base+40]);
}


void initsnd()
{
    SND_CTRL = SND_RST;

    int bgmsize = readfile(BGM_BASE, BGM_FILE);
    int sesize = readfile(SE_BASE, SE_FILE);

    /* サイズを抽出してサウンド回路を起動 */
    xil_printf("BGM data size = %x(HEX) %d(DEC)\n", bgmsize, bgmsize);
    xil_printf("SE data size = %x(HEX) %d(DEC)\n", sesize, sesize);
    BGM_ADDR = 0x20000000 + BGM_BASE;
    BGM_SIZE = bgmsize;
    SE_ADDR = 0x20000000 + SE_BASE;
    SE_SIZE = sesize;
    SND_VOL  = 0x8040;
}

void bgm_on()
{
    SND_CTRL = SND_BGM_PLAY;
}

void se_on()
{
    SND_CTRL = SND_SE_PLAY;
}

void snd_rst()
{
    SND_CTRL = SND_RST;
}