//=========================================================================
// IntMul Unit Test Harness
//=========================================================================
// This harness is meant to be instantiated for a specific implementation
// of the multiplier using the special IMPL macro like this:
//
//  `define LAB1_IMUL_IMPL lab1_imul_Impl
//
//  `include "lab1-imul-Impl.v"
//  `include "lab1-imul-test-harness.v"
//

`include "vc-TestRandDelaySource.v"
`include "vc-TestRandDelaySink.v"

`include "vc-preprocessor.v"
`include "vc-test.v"
`include "vc-trace.v"

//------------------------------------------------------------------------
// Helper Module
//------------------------------------------------------------------------

module TestHarness
(
  input  logic        clk,
  input  logic        reset,
  input  logic [31:0] src_max_delay,
  input  logic [31:0] sink_max_delay,
  output logic        done
);

  logic [63:0] src_msg;
  logic        src_val;
  logic        src_rdy;
  logic        src_done;

  logic [31:0] sink_msg;
  logic        sink_val;
  logic        sink_rdy;
  logic        sink_done;

  vc_TestRandDelaySource#(64) src
  (
    .clk        (clk),
    .reset      (reset),

    .max_delay  (src_max_delay),

    .val        (src_val),
    .rdy        (src_rdy),
    .msg        (src_msg),

    .done       (src_done)
  );

  `LAB1_IMUL_IMPL imul
  (
    .clk        (clk),
    .reset      (reset),

    .req_msg    (src_msg),
    .req_val    (src_val),
    .req_rdy    (src_rdy),

    .resp_msg   (sink_msg),
    .resp_val   (sink_val),
    .resp_rdy   (sink_rdy)
  );

  vc_TestRandDelaySink#(32) sink
  (
    .clk        (clk),
    .reset      (reset),

    .max_delay  (sink_max_delay),

    .val        (sink_val),
    .rdy        (sink_rdy),
    .msg        (sink_msg),

    .done       (sink_done)
  );

  assign done = src_done && sink_done;

  `VC_TRACE_BEGIN
  begin
    src.trace( trace_str );
    vc_trace.append_str( trace_str, " > " );
    imul.trace( trace_str );
    vc_trace.append_str( trace_str, " > " );
    sink.trace( trace_str );
  end
  `VC_TRACE_END

endmodule

//------------------------------------------------------------------------
// Main Tester Module
//------------------------------------------------------------------------

module top;
  `VC_TEST_SUITE_BEGIN( `VC_PREPROCESSOR_TOSTR(`LAB1_IMUL_IMPL) )

  // Not really used, but the python-generated verilog will set this

  integer num_inputs;

  //----------------------------------------------------------------------
  // Test setup
  //----------------------------------------------------------------------

  // Instantiate the test harness

  reg         th_reset = 1;
  reg  [31:0] th_src_max_delay;
  reg  [31:0] th_sink_max_delay;
  wire        th_done;

  TestHarness th
  (
    .clk            (clk),
    .reset          (th_reset),
    .src_max_delay  (th_src_max_delay),
    .sink_max_delay (th_sink_max_delay),
    .done           (th_done)
  );

  // Helper task to initialize sorce sink

  task init
  (
    input [ 9:0] i,
    input [31:0] a,
    input [31:0] b,
    input [31:0] result
  );
  begin
    th.src.src.m[i]   = { a, b };
    th.sink.sink.m[i] = result;
  end
  endtask

  // Helper task to initialize source/sink

  task init_rand_delays
  (
    input [31:0] src_max_delay,
    input [31:0] sink_max_delay
  );
  begin
    th_src_max_delay  = src_max_delay;
    th_sink_max_delay = sink_max_delay;
  end
  endtask

  // Helper task to run test

  task run_test;
  begin
    #1;   th_reset = 1'b1;
    #20;  th_reset = 1'b0;

    while ( !th_done && (th.vc_trace.cycles < 5000) ) begin
      th.display_trace();
      #10;
    end

    `VC_TEST_NET( th_done, 1'b1 );
  end
  endtask

  //----------------------------------------------------------------------
  // Test Case: small positive * positive
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 1, "small positive * positive" )
  begin
    init_rand_delays( 0, 0 );
    init( 0, 32'd02, 32'd03, 32'd6   );
    init( 1, 32'd04, 32'd05, 32'd20  );
    init( 2, 32'd03, 32'd04, 32'd12  );
    init( 3, 32'd10, 32'd13, 32'd130 );
    init( 4, 32'd08, 32'd07, 32'd56  );
    run_test;
  end
  `VC_TEST_CASE_END

  // Add more directed tests here as separate test cases, do not just
  // make the above test case larger. Once you have finished adding
  // directed tests, move on to adding random tests.


  //----------------------------------------------------------------------
  // Test Case: small positive * small negative
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 2, "small positive * small negative" )
  begin
    init_rand_delays( 0, 0 );
    init( 0, 32'd2, -32'd3, -32'd6  );  //  2 * -3 = -6
    init( 1, 32'd4, -32'd5, -32'd20 );  //  4 * -5 = -20
    init( 2, 32'd3, -32'd4, -32'd12 );  //  3 * -4 = -12
    init( 3, 32'd10, -32'd13, -32'd130);  // 10 * -13 = -130
    init( 4, 32'd8, -32'd7, -32'd56 );  //  8 * -7 = -56
    run_test;
  end
 `VC_TEST_CASE_END


  //----------------------------------------------------------------------
  // Test Case: small negative * small positive
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 3, "small negative * small positive" )
  begin
    init_rand_delays( 0, 0 );
    init( 0, -32'd2, 32'd3, -32'd6  );  //  -2 * 3 = -6
    init( 1, -32'd4, 32'd5, -32'd20 );  //  -4 * 5 = -20
    init( 2, -32'd3, 32'd4, -32'd12 );  //  -3 * 4 = -12
    init( 3, -32'd10, 32'd13, -32'd130);  // -10 * 13 = -130
    init( 4, -32'd8, 32'd7, -32'd56 );  //  -8 * 7 = -56
    run_test;
  end
 `VC_TEST_CASE_END


  //----------------------------------------------------------------------
  // Test Case: small negative * small negative
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 4, "small negative * small negative" )
  begin
    init_rand_delays( 0, 0 );
    init( 0, -32'd2, -32'd3, 32'd6  );  //  -2 * -3 = 6
    init( 1, -32'd4, -32'd5, 32'd20 );  //  -4 * -5 = 20
    init( 2, -32'd3, -32'd4, 32'd12 );  //  -3 * -4 = 12
    init( 3, -32'd10, -32'd13, 32'd130);  // -10 * -13 = 130
    init( 4, -32'd8, -32'd7, 32'd56 );  //  -8 * -7 = 56
    run_test;
  end
 `VC_TEST_CASE_END

   //----------------------------------------------------------------------
  // Test Case: large positive * large positive
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 5, "large positive * large positive" )
  begin
    init_rand_delays( 0, 0 );
    init( 0, 32'd10000, 32'd10000, 32'd100000000 );  //  10000 * 10000 = 100000000
    init( 1, 32'd20000, 32'd30000, 32'd600000000 );  //  20000 * 30000 = 600000000
    init( 2, 32'd25000, 32'd25000, 32'd625000000 );  //  25000 * 25000 = 625000000
    init( 3, 32'd30000, 32'd10000, 32'd300000000 );  //  30000 * 10000 = 300000000
    init( 4, 32'd32000, 32'd31000, 32'd992000000 );  //  32000 * 31000 = 992000000
    run_test;
  end
 `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // Test Case: large positive * large negative
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 6, "large positive * large negative" )
  begin
    init_rand_delays( 0, 0 );
    init( 0, 32'd10000, -32'd10000, -32'd100000000 );  //  10000 * -10000 = -100000000
    init( 1, 32'd20000, -32'd30000, -32'd600000000 );  //  20000 * -30000 = -600000000
    init( 2, 32'd25000, -32'd25000, -32'd625000000 );  //  25000 * -25000 = -625000000
    init( 3, 32'd30000, -32'd10000, -32'd300000000 );  //  30000 * -10000 = -300000000
    init( 4, 32'd32000, -32'd31000, -32'd992000000 );  //  32000 * -31000 = -992000000
    run_test;
  end
   `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // Test Case: large negative * large positive
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 7, "large negative * large positive" )
  begin
    init_rand_delays( 0, 0 );
    init( 0, -32'd10000, 32'd10000, -32'd100000000 );  // -10000 * 10000 = -100000000
    init( 1, -32'd20000, 32'd30000, -32'd600000000 );  // -20000 * 30000 = -600000000
    init( 2, -32'd25000, 32'd25000, -32'd625000000 );  //  -25000 * 25000 = -625000000
    init( 3, -32'd30000, 32'd10000, -32'd300000000 );  //  -30000 * 10000 = -300000000
    init( 4, -32'd32000, 32'd31000, -32'd992000000 );  //  -32000 * 31000 = -992000000
    run_test;
  end
  
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // Test Case: large negative * large negative
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 8, "large negative * large negative" )
  begin
    init_rand_delays( 0, 0 );
    init( 0, -32'd10000, -32'd10000, 32'd100000000 );  // -10000 * -10000 = 100000000
    init( 1, -32'd20000, -32'd30000, 32'd600000000 );  // -20000 * -30000 = 600000000
    init( 2, -32'd25000, -32'd25000, 32'd625000000 );  // -25000 * -25000 = 625000000
    init( 3, -32'd30000, -32'd10000, 32'd300000000 );  // -30000 * -10000 = 300000000
    init( 4, -32'd32000, -32'd31000, 32'd992000000 );  // -32000 * -31000 = 992000000
    run_test;
  end
 `VC_TEST_CASE_END



  //----------------------------------------------------------------------
  // Test Case: Mixed scenarios with LSBs masked off
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 9, "Mixed scenarios with LSBs masked off" )
  begin
    init_rand_delays( 0, 0 );

    // Large positive * Large negative with LSBs masked off
    init( 0, (32'd10000 & 32'hFFF0), (-32'd15000 & 32'hFFF0), (32'd10000 & 32'hFFF0) * (-32'd15000 & 32'hFFF0) );

    // Small positive * Large positive with LSBs masked off
    init( 1, (32'd2000 & 32'hFFF0), (32'd3000 & 32'hFFF0), (32'd2000 & 32'hFFF0) * (32'd3000 & 32'hFFF0) );

    // Large negative * Small negative with LSBs masked off
    init( 2, (-32'd40000 & 32'hFFF0), (-32'd500 & 32'hFFF0), (-32'd40000 & 32'hFFF0) * (-32'd500 & 32'hFFF0) );

    // Small positive * Small negative with LSBs masked off
    init( 3, (32'd40 & 32'hFFF0), (-32'd50 & 32'hFFF0), (32'd40 & 32'hFFF0) * (-32'd50 & 32'hFFF0) );

    // Large positive * Large positive with LSBs masked off
    init( 4, (32'd30000 & 32'hFFF0), (32'd20000 & 32'hFFF0), (32'd30000 & 32'hFFF0) * (32'd20000 & 32'hFFF0) );

    run_test;
  end
  `VC_TEST_CASE_END


  //----------------------------------------------------------------------
  // Test Case: Mixed scenarios with middle bits masked off
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 10, "Mixed scenarios with middle bits masked off" )
  begin
    init_rand_delays( 0, 0 );

    // Large positive * Large negative with LSBs masked off
    init( 0, (32'd10000 & 32'hF00F), (-32'd15000 & 32'hF00F), (32'd10000 & 32'hF00F) * (-32'd15000 & 32'hF00F) );

    // Small positive * Large positive with LSBs masked off
    init( 1, (32'd2000 & 32'hF00F), (32'd3000 & 32'hF00F), (32'd2000 & 32'hF00F) * (32'd3000 & 32'hF00F) );

    // Large negative * Small negative with LSBs masked off
    init( 2, (-32'd40000 & 32'hF00F), (-32'd500 & 32'hF00F), (-32'd40000 & 32'hF00F) * (-32'd500 & 32'hF00F) );

    // Small positive * Small negative with LSBs masked off
    init( 3, (32'd40 & 32'hF00F), (-32'd50 & 32'hF00F), (32'd40 & 32'hF00F) * (-32'd50 & 32'hF00F) );

    // Large positive * Large positive with LSBs masked off
    init( 4, (32'd30000 & 32'hF00F), (32'd20000 & 32'hF00F), (32'd30000 & 32'hF00F) * (32'd20000 & 32'hF00F) );

    run_test;
  end
  `VC_TEST_CASE_END


  //----------------------------------------------------------------------
  // Test Case: Multiplying sparse numbers with many zeros but few ones
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 11, "Multiplying sparse numbers with many zeros but few ones" )
  begin
    init_rand_delays( 0, 0 );

    // Sparse Large Positive * Sparse Small Positive
    init( 0, 32'b10000000000000000000000000000001, 32'b00000000000000000000000000000101, 32'b10000000000000000000000000000001 * 32'b00000000000000000000000000000101 );

    // Sparse Small Negative * Sparse Large Negative
    init( 1, -32'b00000000000000000000000000010101, -32'b10000000000000000000000000000001, -32'b00000000000000000000000000010101 * -32'b10000000000000000000000000000001 );

    // Sparse Large Positive * Sparse Large Negative
    init( 2, 32'b10000000000000000000000000000010, -32'b10000000000000000000000000000100, 32'b10000000000000000000000000000010 * -32'b10000000000000000000000000000100 );

    // Sparse Small Positive * Sparse Small Negative
    init( 3, 32'b00000000000000000000000000001010, -32'b00000000000000000000000000000101, 32'b00000000000000000000000000001010 * -32'b00000000000000000000000000000101 );

    // Sparse Large Positive * Sparse Large Positive
    init( 4, 32'b10000000000000000000000000000001, 32'b10000000000000000000000000000100, 32'b10000000000000000000000000000001 * 32'b10000000000000000000000000000100 );

    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // Test Case: Multiplying dense numbers with many ones but few zeros
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 12, "Multiplying dense numbers with many ones but few zeros" )
  begin
    init_rand_delays( 0, 0 );

    // Dense Large Positive * Dense Small Positive
    init( 0, 32'b11111111111111111111111111111110, 32'b11111111111111111111111111111011, 32'b11111111111111111111111111111110 * 32'b11111111111111111111111111111011 );

    // Dense Small Negative * Dense Large Negative
    init( 1, -32'b11111111111111111111111111110101, -32'b11111111111111111111111111111110, -32'b11111111111111111111111111110101 * -32'b11111111111111111111111111111110 );

    // Dense Large Positive * Dense Large Negative
    init( 2, 32'b11111111111111111111111111111101, -32'b11111111111111111111111111111100, 32'b11111111111111111111111111111101 * -32'b11111111111111111111111111111100 );

    // Dense Small Positive * Dense Small Negative
    init( 3, 32'b11111111111111111111111111110110, -32'b11111111111111111111111111111001, 32'b11111111111111111111111111110110 * -32'b11111111111111111111111111111001 );

    // Dense Large Positive * Dense Large Positive
    init( 4, 32'b11111111111111111111111111111101, 32'b11111111111111111111111111111100, 32'b11111111111111111111111111111101 * 32'b11111111111111111111111111111100 );

    run_test;
  end
  `VC_TEST_CASE_END



  //----------------------------------------------------------------------
  // Test Case: random small
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 13, "random small" )
  begin
    init_rand_delays( 0, 0 );
    `include "lab1-imul-gen-input_small.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // Test Case: random large
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 14, "random large" )
  begin
    init_rand_delays( 0, 0 );
    `include "lab1-imul-gen-input_large.py.v"
    run_test;
  end
  `VC_TEST_CASE_END


  //----------------------------------------------------------------------
  // Test Case: random 
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 15, "random numbers" )
  begin
    init_rand_delays( 0, 0 );
    `include "lab1-imul-gen-input_random.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // Test Case: random small w/ random delays
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 16, "random small w/ random delays" )
  begin
    init_rand_delays( 9, 11 );
    `include "lab1-imul-gen-input_small.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  `VC_TEST_CASE_BEGIN( 17, "random small w/ random delays" )
  begin
    init_rand_delays( 2, 3 );
    `include "lab1-imul-gen-input_small.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  `VC_TEST_CASE_BEGIN( 18, "random small w/ random delays" )
  begin
    init_rand_delays( 1, 8 );
    `include "lab1-imul-gen-input_small.py.v"
    run_test;
  end
  `VC_TEST_CASE_END



  //----------------------------------------------------------------------
  // Test Case: random large w/ random delays
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 19, "random large w/ random delays" )
  begin
    init_rand_delays( 8, 6 );
    `include "lab1-imul-gen-input_large.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  `VC_TEST_CASE_BEGIN( 20, "random large w/ random delays" )
  begin
    init_rand_delays( 4, 7 );
    `include "lab1-imul-gen-input_large.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  `VC_TEST_CASE_BEGIN( 21, "random large w/ random delays" )
  begin
    init_rand_delays( 2, 9 );
    `include "lab1-imul-gen-input_large.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  //----------------------------------------------------------------------
  // Test Case: random with random delays
  //----------------------------------------------------------------------

  `VC_TEST_CASE_BEGIN( 22, "random numbers w/ random delays" )
  begin
    init_rand_delays( 3, 3 );
    `include "lab1-imul-gen-input_random.py.v"
    run_test;
  end
  `VC_TEST_CASE_END


  `VC_TEST_CASE_BEGIN( 23, "random numbers w/ random delays" )
  begin
    init_rand_delays( 4, 6 );
    `include "lab1-imul-gen-input_random.py.v"
    run_test;
  end
  `VC_TEST_CASE_END

  `VC_TEST_CASE_BEGIN( 24, "random numbers w/ random delays" )
  begin
    init_rand_delays( 2, 15 );
    `include "lab1-imul-gen-input_random.py.v"
    run_test;
  end
  `VC_TEST_CASE_END


  //----------------------------------------------------------------------
  // Test Case: corner cases for alternative design
  //----------------------------------------------------------------------

`VC_TEST_CASE_BEGIN( 25, "corner cases for alternative design" )
begin
  init_rand_delays( 0, 0 );

  // Your existing cases
  // ...

  // Case 1: b is 32'b1 or 32'b0, a is a real number (e.g., 2147483647)
  `include "lab1-imul-gen-input_corner_smallest.py.v"

  // Case 2: b is a 32-bit number with no successive 0s, a is a real number
  `include "lab1-imul-gen-input_corner_largest.py.v"

  // Case 3: there are 6 successive 0s in every 8 bits of b, a is a different real number
  `include "lab1-imul-gen-input_corner.py.v"

  run_test;
end
`VC_TEST_CASE_END


  `VC_TEST_SUITE_END
endmodule

