//=========================================================================
// Integer Multiplier Variable-Latency Implementation
//=========================================================================

`ifndef LAB1_IMUL_INT_MUL_ALT_V
`define LAB1_IMUL_INT_MUL_ALT_V

`include "lab1-imul-msgs.v"
`include "vc-trace.v"
`include "vc-muxes.v"
`include "vc-regs.v"
`include "vc-arithmetic.v"

// Define datapath and control unit here

module lab1_imul_IntMulAlt_CP
(
 input   logic clk            ,
 input   logic reset          ,
 output  logic a_mux_sel      ,
 output  logic b_mux_sel      ,
 output  logic result_mux_sel ,  
 output  logic result_en      ,
 output  logic add_mux_sel    ,
 input   logic b_lsb          ,
 input   logic beq0           ,
 input   logic req_val        ,
 output  logic req_rdy        ,
 output  logic resp_val       ,
 input   logic resp_rdy        
);

  parameter IDLE = 2'b00;
  parameter CALC = 2'b01;
  parameter DONE = 2'b10;

  logic [1:0] state;

initial begin
  state         <= IDLE;
  a_mux_sel     <= 0 ;
  b_mux_sel     <= 0 ;
  result_mux_sel<= 0 ;
  result_en     <= 0 ;
  add_mux_sel   <= 0 ;
  req_rdy       <= 0 ;
  resp_val      <= 0 ;
end

//NSL
always @(posedge clk) begin
  case(state)
    IDLE  : if (req_val) 
              state <= CALC;
            else
              state <= IDLE;
    CALC  : if (beq0) 
              state <= DONE;
            else
              state <= CALC;
    DONE  : if (resp_rdy) 
              state <= IDLE;
            else
              state <= DONE;
    default:  state <= IDLE;
  endcase
end
//OFL
always @(state, b_lsb) begin
  case(state)
    IDLE  : begin
      a_mux_sel     = 1 ;
      b_mux_sel     = 1 ;
      result_mux_sel= 1 ;
      result_en     = 0 ;
      add_mux_sel   = b_lsb ;
      req_rdy       = 1 ;
      resp_val      = 0 ;
    end
    CALC  : begin
      a_mux_sel     = 0 ;
      b_mux_sel     = 0 ;
      result_mux_sel= 0 ;
      result_en     = 0 ;
      add_mux_sel   = b_lsb ;
      req_rdy       = 0 ;
      resp_val      = 0 ;
    end
    DONE  : begin
      a_mux_sel     = 0 ;
      b_mux_sel     = 0 ;
      result_mux_sel= 0 ;
      result_en     = 1 ;
      add_mux_sel   = b_lsb ;
      req_rdy       = 0 ;
      resp_val      = 1 ;
    end
    default  : begin
      a_mux_sel     = 0 ;
      b_mux_sel     = 0 ;
      result_mux_sel= 0 ;
      result_en     = 0 ;
      add_mux_sel   = b_lsb ;
      req_rdy       = 0 ;
      resp_val      = 0 ;
    end
  endcase
end

endmodule

module lab1_imul_IntMulAlt_DP
(
 input  logic clk,
 input  logic a_mux_sel,
 input  logic b_mux_sel,
 input  logic result_mux_sel,
 input  logic result_en,
 input  logic add_mux_sel,
 output logic b_lsb,
 output logic beq0,
 input  lab1_imul_req_msg_t  req_msg,
 output lab1_imul_resp_msg_t resp_msg
);

parameter A_WIDTH = `LAB1_IMUL_REQ_MSG_A_NBITS;
parameter B_WIDTH = `LAB1_IMUL_REQ_MSG_B_NBITS;
parameter R_WIDTH = `LAB1_IMUL_RESP_MSG_RESULT_NBITS;
parameter SHAMT_WIDTH = 3;
parameter MAXSHAMT    = 7;

wire [A_WIDTH-1:0] out_shift_a;
wire [A_WIDTH-1:0] out_mux_a;
wire [A_WIDTH-1:0] out_reg_a;
wire [B_WIDTH-1:0] out_shift_b;
wire [B_WIDTH-1:0] out_mux_b;
wire [B_WIDTH-1:0] out_reg_b;
wire [SHAMT_WIDTH-1:0] out_shamt_mux[MAXSHAMT-1:0];
wire [SHAMT_WIDTH-1:0] shamt;

wire [R_WIDTH-1:0] out_mux_r;
wire [R_WIDTH-1:0] out_reg_r;
wire [R_WIDTH-1:0] out_addmux_r;
wire [R_WIDTH-1:0] out_add_r;


//logic [31:0] clkcnt ;
//always @(posedge clk) begin
//  if (reset) 
//      clkcnt = 0;
//  else 
//      clkcnt = clkcnt+1;
//end
//always @(posedge clk) begin
//  if((clkcnt > 0)&(clkcnt < 5)) begin
//    $display("=============");
//    $display("state:%b", state);
//    $display("a_mux_sel:%b, b_mux_sel:%b, result_mux_sel:%b, result_en:%b", a_mux_sel,b_mux_sel,result_mux_sel,result_en);
//    $display("out_mux_a:%d, out_mux_b:%d, out_mux_r:%d", out_mux_a,out_mux_b,out_mux_r);
//    $display("out_reg_a:%d, out_reg_b:%d, out_reg_r:%d", out_reg_a,out_reg_b,out_reg_r);
//    $display("b_lsb:%d, beq0:%d, shamt:%d, out_shift_b:%d", b_lsb,beq0,shamt,out_shift_b);
//    $display("out_mux_r:%d, out_reg_r:%d, out_add_r:%d, out_addmux_r:%d, add_mux_sel:%d", out_mux_r,out_reg_r,out_add_r,out_addmux_r,add_mux_sel);
//  end
//end

vc_Mux2  #(
  .p_nbits (B_WIDTH)
)mux_b  (
  .in0(out_shift_b),//input      [p_nbits-1:0]  
  .in1(req_msg.b  ),//input      [p_nbits-1:0] 
  .sel(b_mux_sel  ),//input                    
  .out(out_mux_b  ) //output reg [p_nbits-1:0] 
);

vc_Reg #(
  .p_nbits (B_WIDTH)
)reg_b (
  .clk(clk      ),//input  logic               // Clock input
  .q  (out_reg_b),//output logic [p_nbits-1:0] // Data output
  .d  (out_mux_b) //input  logic [p_nbits-1:0] // Data input
);

assign b_lsb = out_reg_b[0];

vc_ZeroComparator #(
  .p_nbits (B_WIDTH-1)
)bzerodect (
  .in  (out_reg_b[31:1] ),//input  [p_nbits-1:0]
  .out (beq0      ) //output              
);

  vc_Mux2  #(
    .p_nbits (SHAMT_WIDTH)
  )shamt_cal_1  (
    .in0(out_shamt_mux[2]  ),//input      [p_nbits-1:0]  
    .in1(3'd1                 ),//input      [p_nbits-1:0] 
    .sel(out_reg_b[1]      ),//input                    
    .out(out_shamt_mux[1]  ) //output reg [p_nbits-1:0] 
  );
  vc_Mux2  #(
    .p_nbits (SHAMT_WIDTH)
  )shamt_cal_2  (
    .in0(out_shamt_mux[3]  ),//input      [p_nbits-1:0]  
    .in1(3'd2                 ),//input      [p_nbits-1:0] 
    .sel(out_reg_b[2]      ),//input                    
    .out(out_shamt_mux[2]  ) //output reg [p_nbits-1:0] 
  );
  vc_Mux2  #(
    .p_nbits (SHAMT_WIDTH)
  )shamt_cal_3  (
    .in0(out_shamt_mux[4]  ),//input      [p_nbits-1:0]  
    .in1(3'd3                 ),//input      [p_nbits-1:0] 
    .sel(out_reg_b[3]      ),//input                    
    .out(out_shamt_mux[3]  ) //output reg [p_nbits-1:0] 
  );
  vc_Mux2  #(
    .p_nbits (SHAMT_WIDTH)
  )shamt_cal_4  (
    .in0(out_shamt_mux[5]  ),//input      [p_nbits-1:0]  
    .in1(3'd4                 ),//input      [p_nbits-1:0] 
    .sel(out_reg_b[4]      ),//input                    
    .out(out_shamt_mux[4]  ) //output reg [p_nbits-1:0] 
  );
  vc_Mux2  #(
    .p_nbits (SHAMT_WIDTH)
  )shamt_cal_5  (
    .in0(out_shamt_mux[6]  ),//input      [p_nbits-1:0]  
    .in1(3'd5                 ),//input      [p_nbits-1:0] 
    .sel(out_reg_b[5]      ),//input                    
    .out(out_shamt_mux[5]  ) //output reg [p_nbits-1:0] 
  );
  vc_Mux2   #(
    .p_nbits (SHAMT_WIDTH)
  )shamt_cal_6(
    .in0(3'd7                ),//input      [p_nbits-1:0]  
    .in1(3'd6                ),//input      [p_nbits-1:0] 
    .sel(out_reg_b[6]     ),//input                    
    .out(out_shamt_mux[6] ) //output reg [p_nbits-1:0] 
  );
  
assign shamt = out_shamt_mux[1];

vc_RightLogicalShifter #(
  .p_nbits       (B_WIDTH),
  .p_shamt_nbits (SHAMT_WIDTH              )
)Rshift_b (
  .in   (out_reg_b  ),//input        [p_nbits-1:0] 
  .shamt(shamt      ),//input  [p_shamt_nbits-1:0] 
  .out  (out_shift_b) //output       [p_nbits-1:0] 
);

vc_Mux2  #(
  .p_nbits (A_WIDTH)
)mux_a (
  .in0(out_shift_a),//input      [p_nbits-1:0]  
  .in1(req_msg.a  ),//input      [p_nbits-1:0] 
  .sel(a_mux_sel  ),//input                    
  .out(out_mux_a  ) //output reg [p_nbits-1:0] 
);

vc_Reg #(
  .p_nbits (A_WIDTH)
)reg_a (
  .clk(clk      ),//input  logic               // Clock input
  .q  (out_reg_a),//output logic [p_nbits-1:0] // Data output
  .d  (out_mux_a) //input  logic [p_nbits-1:0] // Data input
);

vc_LeftLogicalShifter #(
  .p_nbits       (A_WIDTH),
  .p_shamt_nbits (SHAMT_WIDTH              )
)Lshift_a (
  .in   (out_reg_a  ),//input        [p_nbits-1:0] 
  .shamt(shamt      ),//input  [p_shamt_nbits-1:0] 
  .out  (out_shift_a) //output       [p_nbits-1:0] 
);

vc_Mux2  #(
  .p_nbits (R_WIDTH)
)mux_r (
  .in0(out_addmux_r),//input      [p_nbits-1:0]  
  .in1(0           ),//input      [p_nbits-1:0] 
  .sel(result_mux_sel    ),//input                    
  .out(out_mux_r    ) //output reg [p_nbits-1:0] 
);

vc_Reg #(
  .p_nbits (R_WIDTH)
)reg_r (
  .clk(clk      ),//input  logic               // Clock input
  .q  (out_reg_r),//output logic [p_nbits-1:0] // Data output
  .d  (out_mux_r) //input  logic [p_nbits-1:0] // Data input
);

vc_SimpleAdder #(
  .p_nbits (R_WIDTH)
)sadder (
  .in0 (out_reg_a),//input  [p_nbits-1:0] 
  .in1 (out_reg_r),//input  [p_nbits-1:0] 
  .out (out_add_r) //output [p_nbits-1:0] 
);

vc_Mux2  #(
  .p_nbits (R_WIDTH)
)addmux_r (
  .in0(out_reg_r    ),//input      [p_nbits-1:0]  
  .in1(out_add_r    ),//input      [p_nbits-1:0] 
  .sel(add_mux_sel  ),//input                    
  .out(out_addmux_r ) //output reg [p_nbits-1:0] 
);
vc_Mux2  #(
  .p_nbits (R_WIDTH)
)mux_resp (
  .in0(0            ),//input      [p_nbits-1:0]  
  .in1(out_reg_r    ),//input      [p_nbits-1:0] 
  .sel(result_en    ),//input                    
  .out(resp_msg.result ) //output reg [p_nbits-1:0] 
);


endmodule

//=========================================================================
// Integer Multiplier Variable-Latency Implementation
//=========================================================================

module lab1_imul_IntMulAlt
(
  input  logic                clk,
  input  logic                reset,

  input  logic                req_val,
  output logic                req_rdy,
  input  lab1_imul_req_msg_t  req_msg,

  output logic                resp_val,
  input  logic                resp_rdy,
  output lab1_imul_resp_msg_t resp_msg
);

  //----------------------------------------------------------------------
  // Trace request message
  //----------------------------------------------------------------------

  lab1_imul_ReqMsgTrace req_msg_trace
  (
    .clk   (clk),
    .reset (reset),
    .val   (req_val),
    .rdy   (req_rdy),
    .msg   (req_msg)
  );

  // Instantiate datapath and control models here and then connect them
  // together. As a place holder, for now we simply pass input operand
  // A through to the output, which obviously is not / correct.

logic a_mux_sel      ; 
logic b_mux_sel      ; 
logic result_mux_sel ; 
logic result_en      ; 
logic add_mux_sel    ; 
logic b_lsb          ; 
logic beq0           ; 

lab1_imul_IntMulAlt_CP inmulalt_cp_unit
(
 .clk            (clk           ),//input 
 .reset          (reset         ),//input 
 .a_mux_sel      (a_mux_sel     ),//output   
 .b_mux_sel      (b_mux_sel     ),//output
 .result_mux_sel (result_mux_sel),//output
 .result_en      (result_en     ),//output
 .add_mux_sel    (add_mux_sel   ),//output
 .b_lsb          (b_lsb         ),//input 
 .beq0           (beq0          ),//input 
 .req_val        (req_val       ),//input 
 .req_rdy        (req_rdy       ),//output
 .resp_val       (resp_val      ),//output
 .resp_rdy       (resp_rdy      ) //input 
);
lab1_imul_IntMulAlt_DP inmulalt_dp_unit
(
  .clk              (clk             ),//input  
  .a_mux_sel        (a_mux_sel       ),//input  
  .b_mux_sel        (b_mux_sel       ),//input  
  .result_mux_sel   (result_mux_sel  ),//input  
  .result_en        (result_en       ),//input  
  .add_mux_sel      (add_mux_sel     ),//input  
  .b_lsb            (b_lsb           ),//output 
  .beq0             (beq0            ),//output 
  .req_msg          (req_msg         ),//input  lab1_imul_req_msg_t  
  .resp_msg         (resp_msg        ) //output lab1_imul_resp_msg_t 
);



//  assign req_rdy         = resp_rdy;
//  assign resp_val        = req_val;
//  assign resp_msg.result = req_msg.a;

  //----------------------------------------------------------------------
  // Line Tracing
  //----------------------------------------------------------------------

  `ifndef SYNTHESIS

  reg [`VC_TRACE_NBITS_TO_NCHARS(32)*8-1:0] str;

  `VC_TRACE_BEGIN
  begin

    req_msg_trace.trace( trace_str );

    vc_trace.append_str( trace_str, "(" );

    // Add extra line tracing for internal state here

    $sformat( str, "%x", resp_msg );
    vc_trace.append_val_rdy_str( trace_str, resp_val, resp_rdy, str );

  end
  `VC_TRACE_END

  `endif /* SYNTHESIS */

endmodule

`endif /* LAB1_IMUL_INT_MUL_ALT_V */
