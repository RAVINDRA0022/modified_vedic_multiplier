module vedic_multiplier(
    input [31:0] A,
    input [31:0] B,
    output [63:0] S
);
    wire [31:0] m0, m1, m2, m3;
    wire [31:0] sum1, sum2, carry1, carry2;
    wire [15:0] or_result;
    wire [15:0] adder_out;
    
    vedic_multiplier_16bit V0 (A[15:0], B[15:0], m0);
    vedic_multiplier_16bit V1 (A[31:16], B[15:0], m1);
    vedic_multiplier_16bit V2 (A[15:0], B[31:16], m2);
    vedic_multiplier_16bit V3 (A[31:16], B[31:16], m3);

    csa_32_bit CSA1 (m2, m1, m0[31:16], sum1, carry1);
    csa_32_bit CSA2 (m3, sum1, carry1 << 1, sum2, carry2);

    assign or_result = m0[15:0] | sum2[15:0];

    adder_16bit ADDER (or_result, sum2[31:16], adder_out);

    assign S[15:0] = m0[15:0];
    assign S[47:16] = sum2[31:0];
    assign S[63:48] = adder_out;
endmodule
 
module vedic_multiplier_16bit(
    input [15:0] A,
    input [15:0] B,
    output [31:0] P
);
    wire [15:0] p1, p2, p3, p4;
    wire [31:0] sum1, sum2;
    wire [31:0] carry1, carry2;
    
    wire [7:0] A0 = A[7:0];
    wire [7:0] A1 = A[15:8];
    wire [7:0] B0 = B[7:0];
    wire [7:0] B1 = B[15:8];

    vedic_8bit v0 (A0, B0, p1);
    vedic_8bit v1 (A1, B0, p2);
    vedic_8bit v2 (A0, B1, p3);
    vedic_8bit v3 (A1, B1, p4);

    csa_32_bit csa1 ({16'b0, p3}, {16'b0, p2}, {8'b0, p1[15:8], 8'b0}, sum1, carry1);
    csa_32_bit csa2 ({p4, 16'b0}, sum1, carry1 << 1, sum2, carry2);

    assign P[15:0] = p1[15:0];
    assign P[31:16] = sum2[31:16];
endmodule
module vedic_8bit(
    input [7:0] A, B,
    output [15:0] P
);
    wire [7:0] p1, p2, p3, p4;
    wire [15:0] sum1, sum2;
    wire [15:0] carry1, carry2;

    wire [3:0] A0 = A[3:0];
    wire [3:0] A1 = A[7:4];
    wire [3:0] B0 = B[3:0];
    wire [3:0] B1 = B[7:4];

    vedic_4bit v0 (A0, B0, p1);
    vedic_4bit v1 (A1, B0, p2);
    vedic_4bit v2 (A0, B1, p3);
    vedic_4bit v3 (A1, B1, p4);

    csa_16_bit csa1 (p3, p2, {4'b0, p1[7:4]}, sum1, carry1);
    csa_16_bit csa2 (p4, sum1, carry1 << 1, sum2, carry2);

    assign P[7:0] = p1[7:0];
    assign P[15:8] = sum2[15:8];
endmodule

module vedic_4bit(
    input [3:0] A, B,
    output [7:0] P
);
    assign P = A * B;
endmodule

module csa_32_bit (
    input [31:0] X, Y, Z, // Three input numbers
    input CIN,             // Carry-in for the multiplexers
    output [31:0] S,       // Final sum output
    output COUT            // Final carry output
);
    wire [31:0] sum_fa, carry_fa; // Outputs from Full Adders
    wire [31:0] mux_sum, mux_carry; // MUX outputs

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : full_adder_block
            full_adder FA (
                .a(X[i]), 
                .b(Y[i]), 
                .cin(Z[i]), 
                .sum(sum_fa[i]), 
                .cout(carry_fa[i])
            );

            mux2x1 MUX_SUM (
                .d0(sum_fa[i]), 
                .d1(carry_fa[i]), 
                .sel(CIN), 
                .out(mux_sum[i])
            );

            mux2x1 MUX_CARRY (
                .d0(carry_fa[i]), 
                .d1(1'b0), // Assuming the second input is '0' based on the diagram
                .sel(CIN), 
                .out(mux_carry[i])
            );
        end
    endgenerate

    assign S = mux_sum;
    assign COUT = mux_carry[31]; // Final carry from the last stage
endmodule

// Full Adder Module
module full_adder (
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (cin & a);
endmodule

// 2x1 Multiplexer
module mux2x1 (
    input d0, d1, sel,
    output out
);
    assign out = sel ? d1 : d0;
endmodule

module csa_16_bit (
    input [15:0] X, Y, Z, // Three input numbers
    input CIN,            // Carry-in for the multiplexers
    output [15:0] S,      // Final sum output
    output COUT           // Final carry output
);
    wire [15:0] sum_fa, carry_fa; // Outputs from Full Adders
    wire [15:0] mux_sum, mux_carry; // MUX outputs

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : full_adder_block
            full_adder FA (
                .a(X[i]), 
                .b(Y[i]), 
                .cin(Z[i]), 
                .sum(sum_fa[i]), 
                .cout(carry_fa[i])
            );

            mux2x1 MUX_SUM (
                .d0(sum_fa[i]), 
                .d1(carry_fa[i]), 
                .sel(CIN), 
                .out(mux_sum[i])
            );

            mux2x1 MUX_CARRY (
                .d0(carry_fa[i]), 
                .d1(1'b0), // Assuming the second input is '0' based on the diagram
                .sel(CIN), 
                .out(mux_carry[i])
            );
        end
    endgenerate

    assign S = mux_sum;
    assign COUT = mux_carry[15]; // Final carry from the last stage
endmodule

// Full Adder Module
module full_adder (
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (cin & a);
endmodule

// 2x1 Multiplexer
module mux2x1 (
    input d0, d1, sel,
    output out
);
    assign out = sel ? d1 : d0;
endmodule


module adder_16bit (
    input [15:0] A,
    input [15:0] B,
    output [15:0] Sum
);
    assign Sum = A + B;
endmodule