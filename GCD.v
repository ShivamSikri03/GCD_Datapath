module gcd_datapath(LT,GT,EQ,LdA,LdB,sel1,sel2,sel_in,data_in,clk);
    input LdA,LdB;
    input [15:0] data_in;
    input sel1,sel2,sel_in,clk;
    output LT,GT,EQ;

    wire [15:0] bus,sub_out,Aout,Bout,X,Y;
    
    pipo1 A (Aout,bus,LdA,clk);
    pipo1 B (Bout,bus,LdB,clk);
    comp cmp (LT,GT,EQ,Aout,Bout);
    mux1 M1 (X,Aout,Bout,sel1);
    mux1 M2 (Y,Aout,Bout,sel2);
    subtractor sub (sub_out,X,Y);
    mux1 M3 (bus,sub_out,data_in,sel_in);
    endmodule

module pipo1(Dout,Din,ld,clk);
    input [15:0] Din;
    input ld,clk;
    output reg [15:0] Dout;

    always @(posedge clk) begin
        if(ld) Dout<=Din;
    end
    endmodule

module comp(lt,gt,eq,in1,in2);
    input [15:0] in1,in2;
    output reg lt,gt,eq;

    always @(*) begin
        if(in1<in2) begin
            lt<=1;
            gt<=0;
            eq<=0;
        end
        else if(in1>in2) begin 
            lt<=0;
            gt<=1;
            eq<=0;
        end
        else begin
            lt<=0;
            gt<=0;
            eq<=1;
        end
    end
endmodule

module mux1(Dout,in1,in2,sel);
    input [15:0] in1,in2;
    input sel;
    output reg [15:0] Dout;
    
    always @(*) begin 
        if(sel) Dout<=in2;
        else Dout<=in1;
    end
    endmodule

module subtractor(out,X,Y);
    input [15:0] X,Y;
    output reg [15:0] out;

    always @(*) begin 
        out<=X-Y;
    end
endmodule

module gcd_controller(LdA,LdB,sel1,sel2,sel_in,done,LT,GT,EQ,data_in,start,clk);
    input [15:0] data_in;
    input LT,GT,EQ,start,clk;
    output reg LdA,LdB,sel1,sel2,sel_in,done;
    reg [2:0] state;
    parameter s0 =3'b000,s1=3'b001,s2=3'b010,s3=3'b011,s4=3'b100,s5=3'b101 ;

    always @(posedge clk) begin
        case(state) 
            s0 : if(start) state<=s1;
            s1 : state<=s2;
            s2 : #2 if(EQ) state<=s5;
                    else if(LT) state<=s3;
                    else if(GT) state<=s4;
            s3 : #2 if(EQ) state<=s5;
                    else if(LT) state<=s3;
                    else if(GT) state<=s4;
            s4 : #2 if(EQ) state<=s5;
                    else if(LT) state<=s3;
                    else if(GT) state<=s4;
            s5 : state<=s5;
            default : state<=s0;
        endcase
    end        

    always @(posedge clk) begin
        case(state)
            s0 : begin
                sel_in<=1; LdA<=1; LdB<=0; done<=0;
            end
            s1 : begin
                sel_in<=1; LdA<=0; LdB<=1; done<=0;
            end
            s2 : begin 
                if(LT) begin
                    sel1<=1; sel2<=0; sel_in<=0;
                    #1 LdA<=0; LdB<=1;              //Don't Know How??
                end
                else if(EQ) done<=1;
                else if(GT) begin
                    sel1<=0; sel2<=1; sel_in<=0;
                    #1 LdA<=1; LdB<=0;              //Don't know How?
                end
            end
            s3 : begin
                   if(LT) begin
                    sel1<=1; sel2<=0; sel_in<=0;
                    #1 LdA<=0; LdB<=1;              //Don't Know How??
                end
                else if(EQ) done<=1;
                else if(GT) begin
                    sel1<=0; sel2<=1; sel_in<=0;
                    #1 LdA<=1; LdB<=0;              //Don't know How?
                end
            end
            s4 : begin
                if(LT) begin
                    sel1<=1; sel2<=0; sel_in<=0;
                    #1 LdA<=0; LdB<=1;              //Don't Know How??
                end
                else if(EQ) done<=1;
                else if(GT) begin
                    sel1<=0; sel2<=1; sel_in<=0;
                    #1 LdA<=1; LdB<=0;              //Don't know How?
                end
            end
            s5 : begin
                done<=1;
                sel1<=0;
                sel2<=0;
                sel_in<=0;
                LdA<=0;
                LdB<=0;
            end
            default : begin
                LdA<=0;
                LdB<=0;
            end
        endcase
    end
endmodule


module TEST_GCD;
    reg [15:0] data_in;
    reg clk,start;
    wire done;

    reg [15:0] A,B;

    gcd_datapath DP(LT,GT,EQ,LdA,LdB,sel1,sel2,sel_in,data_in,clk);
    gcd_controller CTR(LdA,LdB,sel1,sel2,sel_in,done,LT,GT,EQ,data_in,start,clk);

    initial begin 
        clk = 1'b0;
        #2 start = 1'b1;
        #1000 $finish;
    end

    always @(*) begin
        #5 clk=~clk;
    end

    initial begin
        #12 data_in = 143;
        #10 data_in = 78;
    end

    initial begin
        $monitor ($time, " %d , %b",DP.Aout,done);
        $dumpfile("gcd.vcd");
        $dumpvars(0,TEST_GCD);
    end

endmodule


