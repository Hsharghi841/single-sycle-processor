// concatenating a, b
// {a, b}
// replicating a four times {4{a}}
// concat and replicate
// {{4{a}}, {3{b}}}

`define period 10
module test(input CLOCK_50 ,[6:0] output HEX0 ,[6:0] output HEX1 ,[6:0]output HEX2,[6:0]output HEX3);
reg clk, rst;
clock_divider my_divider (
    .clk_50MHz(CLOCK_50),  // اتصال به کلاک 50 مگاهرتز
    .reset(reset),          // اتصال به سیگنال ریست
    .clk_2Hz(clk)       // کلاک خروجی 2 هرتز
);
	cpu dut (clk, rst);
	wire n[27:0]
	bintobcd b(.number(dut.rf.cells[30]),.milion(n[27:24]) ,.hundredsthouzands(n[23:20]),.tenthouzand(n[19:16]),.thouzands(n[15:12]),.hundreds(n[11:8]), .tens(n[7:4]), ones(n[3:0]));
	char_to_hex c1(.char(n[3:0],.seg(HEX0));
	char_to_hex c3(.char(n[7:4],.seg(HEX1));
	char_to_hex c2(.char(n[11:8],.seg(HEX2));
	char_to_hex c4(.char(n[15:12],.seg(HEX3));
	integer i;
	always #(`period/2) clk = ~clk;
	initial begin
		clk = 1;
		rst = 1;
		#1;
		rst = 0;
		 
		#`period;
		for (i = 0; i < 32; i = i + 1)
			$display ("r[%d]=%d", i, dut.rf.cells[i]);
		$finish;
	end
endmodule

// for executing r-type instructions only
`define instMemory 0
`define dataMemory 1

module cpu (input clk, rst);

	wire [31:0] pcOut, instruction, dmOut, aluOut, rfRd1, rfRd2;
	wire [31:0] immGenOut;
	wire [3:0] aluop;
	wire memToReg, regWrite, memRead, memWrite, jalr, jal, beq, zero, bltu;
	
	// assign regWrite = 1;
	// assign alusrc = 0;
	// assign memRead = 0;
	// assign memWrite = 0;
	// assign memToReg = 0;

	controlUnit cu (.inst(instruction), .aluop(aluop), .alusrc(alusrc), .memRead(memRead), 
					.regWrite(regWrite), .memToReg(memToReg), .memWrite(memWrite), .jalr(jalr), .jal(jal), .beq(beq), .bltu(bltu));	

	immGen ig (.inst(instruction), .immGenOut(immGenOut));
	
	register PC (
		.clk(clk),
		.rst (rst),
		.in (jalr ? {aluOut & -2} : (jal | (beq & zero) | (bltu & aluOut[31]) ? (immGenOut << 1) + pcOut : pcOut + 4)),
		.out (pcOut)
	);

	instructionMemory im (
		.clock (clk),
		.address (pcOut),
		.q (instruction)
	);

	registerFile rf (
		.clk (clk),
		.rst (rst),
		.rs1(instruction [19:15]),
		.rs2(instruction [24:20]),
		.rd(instruction [11:7]),
		.wrData (memToReg ? dmOut : (jal | jalr ? pcOut + 4 : aluOut)),
		.regWrite (regWrite),
		.rdData1 (rfRd1),
		.rdData2 (rfRd2)
	);

	alu aluInstance (
		.op1(rfRd1),
		.op2(alusrc ? immGenOut : rfRd2),
		.aluop(aluop),
		.result(aluOut),
		.zero(zero)
	);

	memory dm (
		.clk(clk),
		.rst(rst),
		.memRead(memRead),
		.memWrite(memWrite),
		.addressIn(aluOut),
		.dataIn(rfRd2),
		.out(dmOut)
	);
	
endmodule

module register (input clk, rst, input [31:0] in, output reg [31:0] out);
	always @(posedge clk, posedge rst) begin
		if (rst)
			out <= 32'd0;
		else
			out <= in;
	end
endmodule

module memory (input clk, rst, memRead, memWrite, input [31:0] addressIn, dataIn, output [31:0] out);
	reg [7:0] cells [1023:0];
	always @(posedge clk, posedge rst) begin
		if (rst) begin
			for(i = 0; i < 1024; i = i + 1) begin
				cells[i] <= 8'b0;
			end
		end
		// little endian
		else if (memWrite) begin
			cells[(addressIn+0) % 1024] <= dataIn   [7:0];
			cells[(addressIn+1) % 1024] <= dataIn [15:8];
			cells[(addressIn+2) % 1024] <= dataIn [23:16];
			cells[(addressIn+3) % 1024] <= dataIn [31:24];
		end
		// big endian
		// else if (memWrite) begin
		// 	cells[addressIn] <= dataIn   [31:24];
		// 	cells[addressIn+1] <= dataIn [23:16];
		// 	cells[addressIn+2] <= dataIn [15:8];
		// 	cells[addressIn+3] <= dataIn [7:0];
		// end
	end
	// little endian
	assign out [7:0]   = memRead ? cells[(addressIn+0) % 1024] : 8'd0;
	assign out [15:8]  = memRead ? cells[(addressIn+1) % 1024] : 8'd0;
	assign out [23:16] = memRead ? cells[(addressIn+2) % 1024]  : 8'd0;
	assign out [31:24] = memRead ? cells[(addressIn+3) % 1024]   : 8'd0;
	// big endian
	// assign out [31:24] = memRead ? cells[addressIn]   : 8'd0;
	// assign out [23:16] = memRead ? cells[addressIn+1] : 8'd0;
	// assign out [15:8] = memRead ? cells[addressIn+2]  : 8'd0;
	// assign out [7:0] = memRead ? cells[addressIn+3]   : 8'd0;
endmodule

module registerFile (input clk, rst, regWrite, input [4:0] rs1, rs2, rd, input [31:0] wrData, output [31:0] rdData1, rdData2);
	reg [31:0] cells [31:0];
	always @(posedge clk, posedge rst) begin
		if (rst)
			$readmemh("reg.hex", cells);
		else if (regWrite)
			cells [rd] <= wrData;
		cells[0] = 0;
	end
	assign rdData1 = cells[rs1];
	assign rdData2 = cells[rs2];
endmodule

`define ADD 0
`define SUB 1
`define AND 2
`define XOR 3

module alu (input [31:0] op1, op2, input [3:0] aluop, output zero, output reg [31:0] result);
	
	always @(*) begin
		case (aluop)
			`ADD: result = op1 + op2;
			`SUB: result = op1 - op2;
			`AND: result = op1 & op2;
			`XOR: result = op1 ^ op2;
		endcase
	end
	
	assign zero = (result == 0 ? 1'b1 : 0);

endmodule

module immGen(input [31:0] inst, output reg [31:0] immGenOut);
	wire [6:0] opcode = inst [6:0];
	always @(*) begin
		case (opcode)
			7'b0010011, 7'b0000011: begin
				immGenOut = {{20{inst[31]}}, {inst[31:20]}};
			end
			7'b1100111: begin
				immGenOut = {{20{inst[31]}}, inst[31:20]};
			end	
			7'b0100011: begin
				immGenOut = {{20{inst[31]}}, inst[31:25], inst[11:7]};
			end	
			7'b1101111: begin
				immGenOut = {{12{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21]};
			end	
			7'b1100011:begin
				immGenOut = {{20{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8]};
			end	
		endcase
	end
endmodule

module controlUnit (input [31:0] inst, output reg alusrc, memRead, memToReg, regWrite, memWrite, jalr, jal, beq, bltu, [3:0] aluop);
	wire [6:0] opcode = inst [6:0];
	always @(*) begin
		memRead = 0;
		alusrc = 0;
		memToReg = 0;
		regWrite = 1;
		memWrite = 0;
		jalr = 0;
		jal = 0;
		beq = 0;
		bltu = 0;
		case (opcode)
			7'b0110011: begin
				case(inst[31:25])
					7'b0000000: aluop = `ADD;
				 	7'b0100000: aluop = `SUB;
				endcase
			end
			7'b0010011: begin // addi
				alusrc = 1;
				aluop = `ADD;
			end
			7'b0000011: begin // lw
				memRead = 1;
				alusrc = 1;
				memToReg = 1;
				aluop = `ADD;
			end
			7'b0100011: begin // sw
				alusrc = 1;
				regWrite = 0;
				memWrite = 1;
				aluop = `ADD;
			end
			7'b1100111: begin // jalr
				alusrc = 1;
				jalr = 1;
				aluop = `ADD;
			end
			7'b1101111: begin // jal
				jal = 1;
			end
			7'b1100011: begin // beq, bltu
				aluop = `SUB; 
				case (inst[14:12])
					3'b000: beq = 1;
					3'b110: bltu = 1;
				endcase
			end
		endcase
	end
endmodule

module clock_divider (
    input wire clk_50MHz,    // کلاک ورودی 50 مگاهرتز
    input wire reset,        // سیگنال ریست
    output reg clk_2Hz       // کلاک خروجی 2 هرتز
);

// برای تقسیم 50MHz به 2Hz نیاز به تقسیم بر 25,000,000 داریم (50,000,000 / 2 = 25,000,000)
// بنابراین شمارنده باید تا 12,500,000 بشمارد (چون هر سیکل کلاک دو حالت دارد)
reg [23:0] counter; // 24 بیت برای شمارش تا 12,500,000 کافی است (2^24 = 16,777,216)

always @(posedge clk_50MHz or posedge reset) begin
    if (reset) begin
        counter <= 0;
        clk_2Hz <= 0;
    end
    else begin
        if (counter == 12499999) begin // 12,500,000 - 1
            counter <= 0;
            clk_2Hz <= ~clk_2Hz; // تغییر وضعیت کلاک خروجی
        end
        else begin
            counter <= counter + 1;
        end
    end
end

endmodule

