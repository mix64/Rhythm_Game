#include "draw.h"
#include <stdio.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "cojt.h"
#include "init_dvi.h"

#include "ff.h"

void setFrame(int addr, int width, int height)
{
    command(0x20000000);
    command(addr);                  // VRAMADR = 0x20000000
    command(width<<16 | height);    // WIDTH=640, HEIGHT=480
}

void setArea(int posX, int posY, int sizX, int sizY)
{
    command(0x21000000);
    command(posX<<16 | posY);    // POSX=0, POSY=0
    command(sizX<<16 | sizY); // WIDTH=640, HEIGHT=480
}

void setTex(int addr, int fmt)
{
    command(0x22000000 | (fmt&1));
    command(addr);
}

void setStColor(int scolor_l, int scolor_h, char mask)
{
    command(0x31000000 | mask);
    command(scolor_l);
    command(scolor_h);
}

void setBlendAlpha(short ABCDE, char SRCCA, int COEF0, int COEF1)
{
    command(0x33000000 | (ABCDE<<8) | SRCCA);
    command(COEF0);
    command(COEF1);
}

void setBlendOff()
{
    command(0x32000000);
}

void stmod(char mod)
{
    command(0x30000000 | (mod&1));
}

void drw_pat(int color, int dstX, int dstY, int sizX, int sizY)
{
    // setFCOLOR
    command(0x23000000);
    command(color);
    // PATBLT
    command(0x81000000);
    command(dstX<<16 | dstY);   // POSX, POSY
    command(sizX<<16 | sizY);   // DSIZEX, DSIZEY
}

void drw_tex(char *fname, int dstX, int dstY, int sizX, int sizY, int srcX, int srcY)
{
    command(0x82000000);
    command(dstX<<16|dstY);
    command(sizX<<16|sizY);
    command(srcX<<16|srcY);
}

void eodl()
{
    command(0x0F000000);
}

/* 画面クリア */
void dispclear(int frame) {
    int i;
    for ( i=0; i<XSIZE*YSIZE; i++) {
        VRAM[XSIZE*YSIZE*frame+i] = 0;
    }
    Xil_DCacheFlush();
}

/* 描画コマンド書き込み */
void command(int data) {
    DRAWCMD = data;
}

/* 描画開始と終了待ち */
void exe_draw() {
    DRAWCTRL = DRAWEXE;
    while ( (DRAWSTAT & DRAWBUSY) != 0 );
    DRAWCTRL = DRAWRST;
    if ( (DISPCTRL & VBLANK) != 0) {
        xil_printf("X"); // 描画終了時点でVBLANKが来ていたらNG（Xを表示）
        DISPCTRL |= VBLANK;
    }
    else {
        // xil_printf(".");
        while ( (DISPCTRL & VBLANK) ==0 );
        DISPCTRL |= VBLANK;
    }
}

void fileread(char *fname, int page, int xsiz, int ysiz) {

    UINT num;
    FRESULT fr;
    FATFS FatFs;
    FIL Fil;
    char buff[4];
    setVRAM(page);

    /* ファイルを読み込みVRAMに書き込む */
    f_mount(&FatFs, "", 0);
    fr=f_open(&Fil, fname, FA_READ);
    if ( fr ) {
        xil_printf("Open Error!\n");
        return;
    }
    for (int i = 0; i < YSIZE; i++) {
        for (int j = 0; j < XSIZE; j++) {
            if (j < xsiz && i < ysiz) {
                f_read(&Fil, buff, 4, &num);
                VRAM[i*XSIZE + j] = (buff[3] << 24 ) | (buff[2] << 16 ) | (buff[1] << 8 ) | buff[0];
            }
        }
    }
    f_close(&Fil);
    Xil_DCacheFlush();

    setVRAM(0);
    return;
}
