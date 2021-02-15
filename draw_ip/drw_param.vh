/* parameter for draw circuit */

/* command list */
/* system control */
localparam C_NOP  = 8'h00;
localparam C_EODL = 8'h0F;
/* draw parameter */
localparam C_SETFRAME      = 8'h20;
localparam C_SETDRAWAREA   = 8'h21;
localparam C_SETTEXTURE    = 8'h22;
localparam C_SETFCOLOR     = 8'h23;
localparam C_SETSTMODE     = 8'h30;
localparam C_SETSCOLOR     = 8'h31;
localparam C_SETBLENDOFF   = 8'h32;
localparam C_SETBLENDALPHA = 8'h33;
/* block transfer */
localparam C_PATBLT = 8'h81;
localparam C_BITBLT = 8'h82;

/* command size */
/* draw parameter */
localparam N_SETFRAME      = 2'b10;
localparam N_SETDRAWAREA   = 2'b10;
localparam N_SETTEXTURE    = 2'b01;
localparam N_SETFCOLOR     = 2'b01;
localparam N_SETSTMODE     = 2'b00;
localparam N_SETSCOLOR     = 2'b10;
localparam N_SETBLENDOFF   = 2'b00;
localparam N_SETBLENDALPHA = 2'b10;
/* block transfer */
localparam N_PATBLT = 2'b10;
localparam N_BITBLT = 2'b11;

/* errno */
localparam E_CMDMISS = 16'h0001; /* no such command */
localparam E_NOFRAME = 16'h0002; /* not set frame */
localparam E_NODAREA = 16'h0004; /* not set drawarea */
localparam E_BLDMISS = 16'h0008; /* not set brendoff or brendalpha */
localparam E_NOTEODL = 16'h0010; /* not set EODL command */
localparam E_NOCOLOR = 16'h0020; /* Use PATBIT but not set backframe color */ 
localparam E_TEXTURE = 16'h0040; /* Use BITBLT but not set texture */
localparam E_BUFOVER = 16'h0080; /* command buffer is overflow */

