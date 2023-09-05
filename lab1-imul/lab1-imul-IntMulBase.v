//========================================================================
// Integer Multiplier Fixed-Latency Implementation
//========================================================================

`ifndef LAB1_IMUL_INT_MUL_BASE_V
`define LAB1_IMUL_INT_MUL_BASE_V

`include "lab1-imul-msgs.v"
`include "vc-trace.v"
`include "vc-regs.v"
`include "vc-arithmetic.v"
`include "vc-muxes.v"

// Define datapath and control unit here

module imul_base_datapath(resp_msg, b_lsb, req_msg, a_mux_sel, b_mux_sel, add_mux_sel, result_mux_sel, result_en, clk);
	parameter WIDTH = 32;
	input lab1_imul_req_msg_t req_msg;
	input a_mux_sel, b_mux_sel, add_mux_sel, result_mux_sel, result_en, clk;
	output lab1_imul_resp_msg_t resp_msg;
	output b_lsb;

	//wire [WIDTH-1:0]req_msg_a = req_msg[WIDTH-1:0];
	//wire [WIDTH-1:0]req_msg_b = req_msg[2*WIDTH-1:WIDTH];
	wire [WIDTH-1:0]wire_interim[10:0];

	assign b_lsb = wire_interim[6][0];
	assign resp_msg.result = wire_interim[8];

	//always@(posedge clk)begin
	//	$display("WIRE_INTERIM_0:: %d %b", wire_interim[0], wire_interim[0]);
	//	$display("WIRE_INTERIM_1:: %d %b", wire_interim[1], wire_interim[1]);
	//	$display("WIRE_INTERIM_2:: %d %b", wire_interim[2], wire_interim[2]);
	//	$display("WIRE_INTERIM_9:: %d %b", wire_interim[9], wire_interim[9]);
	//	$display("ADD_MUX_SEL:: %b\n", add_mux_sel);
	//end

	vc_Mux2 #(.p_nbits(WIDTH)) mux1 (.in0(wire_interim[0]), .in1(req_msg.b), .sel(b_mux_sel), .out(wire_interim[3]));
	vc_Mux2 #(.p_nbits(WIDTH)) mux2 (.in0(wire_interim[1]),
			     		 .in1(req_msg.a),
		     	     		 .sel(a_mux_sel),
		     	     		 .out(wire_interim[4]));
	vc_Mux2 #(.p_nbits(WIDTH)) mux3 (.in0(wire_interim[2]),
			     		 .in1(0),
			     		 .sel(result_mux_sel),
			     		 .out(wire_interim[5]));
	vc_Mux2 #(.p_nbits(WIDTH)) mux4 (.in0(wire_interim[9]),
			     		 .in1(wire_interim[8]),
			     		 .sel(add_mux_sel),
			     		 .out(wire_interim[2]));

	vc_Reg #(.p_nbits(WIDTH)) dff1 (.clk(clk),
			    		.d(wire_interim[3]),
			    		.q(wire_interim[6]));
	vc_Reg #(.p_nbits(WIDTH)) dff2 (.clk(clk),
			    		.d(wire_interim[4]),
			    		.q(wire_interim[7]));
	vc_Reg #(.p_nbits(WIDTH)) dff3 (.clk(result_en),
			    		.d(wire_interim[5]),
			    		.q(wire_interim[8]));

	vc_RightLogicalShifter #(.p_nbits(WIDTH)) rs (.in(wire_interim[6]),
						   .shamt(1'b1),
						   .out(wire_interim[0]));
	vc_LeftLogicalShifter #(.p_nbits(WIDTH)) ls (.in(wire_interim[7]),
						  .shamt(1'b1),
						  .out(wire_interim[1]));

	vc_SimpleAdder #(.p_nbits(WIDTH)) add (.in0(wire_interim[7]),
				   	       .in1(wire_interim[8]),
				   	       .out(wire_interim[9]));
endmodule

module imul_base_cp(a_mux_sel, b_mux_sel, add_mux_sel, result_mux_sel, result_en, req_val, req_rdy, resp_rdy, resp_val, b_lsb, clk, rst);
	
	parameter IDLE = 2'b00;
	parameter CALC = 2'b01;
	parameter DONE = 2'b10;

	input req_val, resp_rdy, b_lsb, clk, rst;
	output reg a_mux_sel, b_mux_sel, add_mux_sel, result_mux_sel;
	output result_en;
	output reg req_rdy, resp_val;
	reg [1:0]state, next_state;
	reg flag = 1'b1;
	reg [5:0] counter;

	assign result_en = clk & flag;
	//assign result_en = 1'b1;

	//state_memory
	always@(posedge clk)
	begin
		if(rst) state<=IDLE;
		else state<=next_state;
		counter <= counter + 1;
	//	$display("Counter:: %d", counter);
	end

	//output_logic
	always@(state, b_lsb)
	begin
		case(state)
			IDLE:begin
				a_mux_sel = 1'b1;
				b_mux_sel = 1'b1;
				add_mux_sel = 1'b0;
				result_mux_sel = 1'b1;
				flag = 1'b1;
				req_rdy = 1'b1;
				resp_val = 1'b0;
			end
			CALC: begin
				a_mux_sel = 1'b0;
				b_mux_sel = 1'b0;
				result_mux_sel = 1'b0;
				flag = 1'b1; //not sure
				if(b_lsb) add_mux_sel = 1'b0;
				else add_mux_sel = 1'b1;
				req_rdy = 1'b0;
				resp_val = 1'b0;
			end
			DONE: begin
				a_mux_sel = 1'b0;
			        b_mux_sel = 1'b0;
				add_mux_sel = 1'b1;
				flag = 1'b0;
				result_mux_sel = 1'b0;
				req_rdy = 1'b0;
				resp_val = 1'b1;
			end
			default: begin
				a_mux_sel = 1'b1;
				b_mux_sel = 1'b1;
				add_mux_sel = 1'b1;
				flag = 1'b0;
				result_mux_sel = 1'b1;
				req_rdy = 1'b1;
				resp_val = 1'b0;
			end
		endcase
	end

	//next_state_logic
	always@(req_val,resp_rdy,counter) begin
		casex({state,req_val,resp_rdy,counter})
			{IDLE,1'b1,1'bx,6'bxxxxxx}: begin 
							next_state = CALC;
							counter = 6'b0;
						end
			{CALC,1'bx,1'bx,6'b100000}: next_state = DONE;
			{DONE,1'bx,1'b1,6'bxxxxxx}: next_state = IDLE;
			default: next_state = state;
		endcase
	end

endmodule


//module imul_baseline(resp_msg, resp_rdy, req_msg, req_val, clk, rst);
//	
//	parameter WIDTH = 32;
//	input resp_rdy, req_val, clk, rst;
//	input [2*WIDTH-1:0] req_msg;
//	output [WIDTH-1:0] resp_msg;
//
//	wire a_mux_sel, b_mux_sel, add_mux_sel, result_mux_sel, result_en, b_lsb;
//
//	imul_base_cp control_path (.a_mux_sel(a_mux_sel), 
//				   .b_mux_sel(b_mux_sel), 
//				   .add_mux_sel(add_mux_sel), 
//				   .result_mux_sel(result_mux_sel), 
//				   .result_en(result_en), 
//				   .req_val(req_val), 
//				   .resp_rdy(resp_rdy), 
//				   .b_lsb(b_lsb), 
//				   .clk(clk), 
//				   .rst(rst));
//	imul_base_datapath data_path (.resp_msg(resp_msg), 
//				      .b_lsb(b_lsb), 
//				      .req_msg(req_msg), 
//				      .a_mux_sel(a_mux_sel), 
//				      .b_mux_sel(b_mux_sel), 
//				      .add_mux_sel(add_mux_sel), 
//				      .result_mux_sel(result_mux_sel), 
//				      .result_en(result_en), 
//				      .clk(clk));
//	
//endmodule
	


	



//========================================================================
// Integer Multiplier Fixed-Latency Implementation
//========================================================================

module lab1_imul_IntMulBase
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
  // A through to the output, which obviously is not correct.
  wire a_mux_sel, b_mux_sel, add_mux_sel, result_mux_sel, result_en, b_lsb;

  imul_base_cp control_path (.a_mux_sel(a_mux_sel), 
				   .b_mux_sel(b_mux_sel), 
				   .add_mux_sel(add_mux_sel), 
				   .result_mux_sel(result_mux_sel), 
				   .result_en(result_en), 
				   .req_val(req_val),
				   .req_rdy(req_rdy), 
				   .resp_rdy(resp_rdy), 
				   .resp_val(resp_val),
				   .b_lsb(b_lsb), 
				   .clk(clk), 
				   .rst(reset));
  imul_base_datapath data_path (.resp_msg(resp_msg.result), 
				      .b_lsb(b_lsb), 
				      .req_msg(req_msg), 
				      .a_mux_sel(a_mux_sel), 
				      .b_mux_sel(b_mux_sel), 
				      .add_mux_sel(add_mux_sel), 
				      .result_mux_sel(result_mux_sel), 
				      .result_en(result_en), 
				      .clk(clk));  
// assign req_rdy         = resp_rdy;
// assign resp_val        = req_val;
// assign resp_msg.result = req_msg.a;

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

    vc_trace.append_str( trace_str, ")" );

    $sformat( str, "%x", resp_msg );
    vc_trace.append_val_rdy_str( trace_str, resp_val, resp_rdy, str );

  end
  `VC_TRACE_END

  `endif /* SYNTHESIS */

endmodule

`endif /* LAB1_IMUL_INT_MUL_BASE_V */

