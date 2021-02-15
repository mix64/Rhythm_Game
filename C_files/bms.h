#pragma once

#define WIDTH 1280
#define HEIGHT 1024

#define HEIGHT2 (HEIGHT/2)
#define HEIGHT10 (HEIGHT/10)
#define HEIGHT45 (HEIGHT/20*9.f)

#define WIDTH2 (WIDTH/2)
#define WIDTH10 (WIDTH/10)
#define WIDTH12 (WIDTH/12)

#define BMSFILE "union.bms"
#define BPM 201.0
#define FRAME_T (1000.0/60.0)
#define FRAME_D ((HEIGHT - HEIGHT10)/((2*1000.0/(BPM/60.0/4.0))/FRAME_T))

#define NLANE 6

// draw
void drw_frame();
void drw_norts();

// bms file
void bmsinit(char *fname);
void bmsfin();
void readbms();
