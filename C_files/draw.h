#pragma once

void setFrame(int addr, int width, int height);
void setArea(int posX, int posY, int sizX, int sizY);
void setTex(int addr, int fmt);
void setStColor(int scolor_l, int scolor_r, char mask);
void setBlendAlpha(short ABCDE, char SRCCA, int COEF0, int COEF1);
void setBlendOff();
void stmod(char mod);
void drw_pat(int color, int dstX, int dstY, int sizX, int sizY);
void drw_tex(char *fname, int dstX, int dstY, int sizX, int sizY, int srcX, int srcY);
void eodl();

void dispclear(int frame);
void command(int data);
void exe_draw();
void fileread(char *fname, int base, int xsiz, int ysiz);
