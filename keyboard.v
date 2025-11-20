`default_nettype none
module keyboard (CLOCK_50, KEY,SW, PS2_CLK, PS2_DAT, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);

    input wire CLOCK_50;
    input wire [0:0] KEY;
    input wire [9:0] SW;
    inout wire PS2_CLK, PS2_DAT;
    output wire [9:0] LEDR;       // DE-series LEDs
    output wire [6:0] HEX0;
    output wire [6:0] HEX1;       // DE-series HEX displays
    output wire [6:0] HEX2;
    output wire [6:0] HEX3;
    output wire [6:0] HEX4;       // DE-series HEX displays
    output wire [6:0] HEX5;       // DE-series HEX displays
    assign LEDR[0] = 1'b1;        // Start
    wire Resetn;
    assign Resetn = KEY[0];
    wire [23:0] datout;
    wire [23:0] datout_2;
    wire a,b,f,A,B,F,CLOCK_OUT;
    
    get_key gt (CLOCK_50,Resetn,PS2_CLK, PS2_DAT,datout);
    ISTYPE il (datout[7:0],a,b,f);
    assign LEDR[3] = a;
    assign LEDR[4] = b;
    assign LEDR[5] = f;
    FSM fsm(a,b,f,Resetn,CLOCK_50,datout,datout_2,LEDR[1]);
    



    hex7seg aa (datout[3:0],HEX0);
    hex7seg bb (datout[7:4],HEX1);

    // hex7seg c (datout[11:8],HEX2);
    // hex7seg d (datout[15:12],HEX3);
    // hex7seg e (datout[19:16],HEX4);
    // hex7seg f (datout[23:20],HEX5);



endmodule


module get_key(CLOCK_50,Resetn,PS2_CLK, PS2_DAT,DAT_OUT);
    input wire CLOCK_50;
    input wire Resetn;
    input wire PS2_CLK,PS2_DAT;
    output wire [23:0] DAT_OUT;
    reg [32:0] DAT;	// 33-bit data register
    reg prev_ps2_clk;

    wire negedge_ps2_clk;

    always @(posedge CLOCK_50)
        prev_ps2_clk <= PS2_CLK;
    assign negedge_ps2_clk = (prev_ps2_clk & !PS2_CLK);


    always @(posedge CLOCK_50) begin
        if (Resetn == 0) 
            DAT <= 11'b00111100000;

        else if (negedge_ps2_clk) begin
            DAT[31:0] <= DAT[32:1];
            DAT[32] <= PS2_DAT;
        end
    end

    assign DAT_OUT[3:0] = DAT[4:1];
    assign DAT_OUT[7:4] = DAT[8:5];
    assign DAT_OUT[11:8] = DAT[15:12];
    assign DAT_OUT[15:12] = DAT[19:16];
    assign DAT_OUT[19:16] = DAT[26:23];
    assign DAT_OUT[23:20] = DAT[30:27];
endmodule

module ISTYPE(KEY_8,FLAG1,FLAG2,FLAG3);
    input wire [7:0] KEY_8;
    output reg FLAG1;
    output reg FLAG2;
    output reg FLAG3;
    always @(*) begin
        FLAG1 = 0;
        FLAG2 = 0;
        FLAG3 = 0;
        case (KEY_8)
            8'h1C, 8'h32, 8'h21, 8'h23, 8'h24, 8'h2B, 
            8'h34, 8'h33, 8'h43, 8'h3B, 8'h42, 8'h4B,
            8'h3A, 8'h31, 8'h44, 8'h4D, 8'h15, 8'h2D,
            8'h1B, 8'h2C, 8'h3C, 8'h2A, 8'h1D, 8'h22,
            8'h35, 8'h1A:
                FLAG1 = 1;
            8'h0C:
                FLAG2 = 1;
            8'hF0:
                FLAG3 = 1;

        endcase
    end
endmodule


module FSM(A,B,F,RESETN,CLOCK,DATA,DATA_OUT,SHIFT);
input wire A;
input wire B;
input wire F;
input wire RESETN;
input wire CLOCK;
input wire [7:0] DATA;
output wire [7:0] DATA_OUT;
output wire SHIFT;

reg [3:0] y;
reg [3:0] Y;
reg [7:0] SW;
reg  SHIFTSW;


parameter CR=4'h0, PR=4'h1 , RL=4'h2, SH = 4'h3,Q=4'h4;
always @(*)
    case (y)
        CR:begin
            if(F) Y=RL;
            else if(B) Y=SH;
            else if (A) Y=PR;
            
        end
        PR: begin
            if (F) Y=RL;
            else if (A) Y = PR;
            SW = DATA;
        end
        SH: begin
        if(B) Y=SH;
            else if (A) Y=Q;
        end
        Q: begin 
            if (A) Y=Q;
            else if (F) Y=RL;
            SW = DATA;
            SHIFTSW = 1;
        end
        RL: begin 
        if ((A|B)) Y=CR;
        end


        default: begin 
        SHIFTSW = 0;
        SW = 8'b0;
        end
    endcase

always @(posedge CLOCK)
    if (!RESETN) begin y <= CR; SW <=8'b0; SHIFTSW <=0;end
    else y<=Y;

assign SHIFT = SHIFTSW;
assign DATA_OUT = SW;
endmodule


module hex7seg (hex, display);
    input wire [3:0] hex;
    output reg [6:0] display;

    always @ (hex)
    case (hex)
        4'h0: display = 7'b1000000;
        4'h1: display = 7'b1111001;
        4'h2: display = 7'b0100100;
        4'h3: display = 7'b0110000;
        4'h4: display = 7'b0011001;
        4'h5: display = 7'b0010010;
        4'h6: display = 7'b0000010;
        4'h7: display = 7'b1111000;
        4'h8: display = 7'b0000000;
        4'h9: display = 7'b0011000;
        4'hA: display = 7'b0001000;
        4'hb: display = 7'b0000011;
        4'hC: display = 7'b1000110;
        4'hd: display = 7'b0100001;
        4'hE: display = 7'b0000110;
        4'hF: display = 7'b0001110;
    endcase
endmodule
