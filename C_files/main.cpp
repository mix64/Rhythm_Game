#include <stdio.h>
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "cojt.h"
#include "init_dvi.h"

#include "bms.h"
#include "draw.h"
#include "snd.h"

#define PGSIZE (XSIZE*YSIZE*4)
#define TEXTURE_FILE "texture.bin"

int main(int argc, char **argv)
{
    init_tpf410();
    set_resolution(VGA);
    set_disp_page(0);
    setVRAM(0);

    bmsinit(BMSFILE);
    sndinit();
    fileread(TEXTURE_FILE, 2, 336, 336);

    /* VGA */
    wait_vblank();
    DISPFIFO = DSP_FIFO_OVER | DSP_FIFO_UNDER;
    DISPCTRL = DISPON;

    int frame = 0;

    int coef0 = 0;
    int i = 0;
    int flg = 0;

    while(1) {
        setFrame(0x20000000+PGSIZE*frame, XSIZE, YSIZE);
        setArea(0, 0, XSIZE, YSIZE);
        setTex(0x20000000+PGSIZE*2, 0);
        drw_pat(0xFF000000, 0, 0, XSIZE, YSIZE);
        drw_frame();
        drw_norts();

        // test
        // setBlendAlpha(0x054E, 0x00, (coef0<<24), 0xFFFFFFFF);
        stmod(1);
        setStColor(0x0000FFFF, 0x0000FFFF, 0x08);
        drw_tex(TEXTURE_FILE, (XSIZE-400)/2, (YSIZE-400)/2, 336, 336, 0, 0);

        eodl();
        exe_draw();
        set_disp_page(frame);
        if (frame) { frame = 0; }
        else { frame = 1; }
//        i++;
//        if ( i > 480 ) i = 0;
//        if ( flg ) {
//            coef0 -= 4;
//            if ( coef0 <= 0) {
//                flg   = 0;
//                coef0 = 0;
//            }
//        }
//        else {
//            coef0 += 4;
//            if ( coef0 >= 255 ) {
//                flg   = 1;
//                coef0 = 255;
//            }
//        }
    }
}
