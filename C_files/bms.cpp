#include <sstream>
#include <string>
#include <cmath>
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_cache.h"
#include "cojt.h"
#include "init_dvi.h"

#include "snd.h"
#include "bms.h"
#include "draw.h"

#include <stdlib.h>
#include "ff.h"

#define FSIZE 13949
#define BTN (*(volatile unsigned char *)XPAR_AXI_GPIO_1_BASEADDR)

#define BTN0 0x01
#define BTN1 0x02
#define BTN2 0x04
#define BTN3 0x08
#define BTN4 0x10
#define BTN5 0x20
#define BTN6 0x40
#define BTN7 0x80

struct bmshdr {
	float notes[NLANE][1024] = {};
	int index[NLANE];
	int size[NLANE];
	int tick;
} bmshdr;

void bmsinit(char *fname)
{
	// BMSファイルを開く
    UINT num;
    FRESULT fr;
    FATFS FatFs;
	FILINFO fno;
    FIL Fil;

	f_stat(fname, &fno);
    char *buff = (char*)malloc(FSIZE+1);

    f_mount(&FatFs, "", 0);
    fr = f_open(&Fil, fname, FA_READ);
    if (fr) {
        xil_printf("Open Error! : %s\n", fname);
    }
    xil_printf("Reading '%s' on SD Card.\n", fname);
    f_read(&Fil, buff, FSIZE+1, &num);
    f_close(&Fil);
    Xil_DCacheFlush();
	xil_printf("fsize:%d, rdsize:%d\n", FSIZE+1, num);

	for (int i = 0; i < NLANE; i++) {
		bmshdr.index[i] = 0;
		bmshdr.size[i] = 0;
	}
	bmshdr.tick = -140;

	// stringstreamへ変換
	std::string fs(buff);
	std::stringstream fss(fs);
	std::string str;

	while (std::getline(fss, str)) {
		str.erase(str.size()-1, 1);

		if (str.empty()) {
			continue;
		}

		// 小節番号とレーンを取得
		// int bar = std::stoi(str.substr(1, 3));
		// int lane = std::stoi(str.substr(5, 1));
		int bar = atoi(str.substr(1,3).c_str());
		int lane = atoi(str.substr(5,1).c_str());
		if (lane == 0) { continue; }
		if (lane == 8) { lane = 6; };
		lane--; // lane = 0 ~ 5
		str.erase(0, 7);
		for (unsigned int i = 1; i < str.length(); i += 2) {
			if (str.at(i) == '1') {
				bmshdr.notes[lane][bmshdr.size[lane]] = (bar*HEIGHT45 + HEIGHT45 / (str.length() / 2)*(i/2));
				bmshdr.size[lane] += 1;
			}
		}
	}
	free(buff);
}

void drw_frame()
{
	// 判定バー
	drw_pat(0xFFFFFFFF, WIDTH10, HEIGHT - HEIGHT10, WIDTH2, 5);

	// 両端バー
	drw_pat(0xFFFFFFFF, WIDTH10, 0, 5, HEIGHT);
	drw_pat(0xFFFFFFFF, WIDTH10 + WIDTH2, 0, 5, HEIGHT);

	// 区切りバー
	drw_pat(0xFFFFFFFF, WIDTH10 + WIDTH12, 0, 1, HEIGHT);
	drw_pat(0xFFFFFFFF, WIDTH10 + WIDTH12 * 2, 0, 1, HEIGHT);
	drw_pat(0xFFFFFFFF, WIDTH10 + WIDTH12 * 3, 0, 1, HEIGHT);
	drw_pat(0xFFFFFFFF, WIDTH10 + WIDTH12 * 4, 0, 1, HEIGHT);
	drw_pat(0xFFFFFFFF, WIDTH10 + WIDTH12 * 5, 0, 1, HEIGHT);
}

void drw_norts()
{
	bmshdr.tick++;
	if (bmshdr.tick == 0) { bgm_on(); }
	for (int i = 0; i < NLANE; i++) {
		for (unsigned int j = bmshdr.index[i]; j < bmshdr.size[i]; j++) {
			if (bmshdr.notes[i][j] > bmshdr.tick*FRAME_D + HEIGHT) { break; }
			if (bmshdr.notes[i][j] < bmshdr.tick*FRAME_D + HEIGHT10) {
				bmshdr.index[i] += 1;
				se_on();
				// SE再生
				// 入力判定
				continue;
			}
			drw_pat(0xFF00FFFF, WIDTH10 + WIDTH12 * i, static_cast<int>(round(bmshdr.tick*FRAME_D + HEIGHT - bmshdr.notes[i][j])), WIDTH12, 3);
		}
	}
}
