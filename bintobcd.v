module bintobcd(number,milion ,hundredsthouzands,tenthouzand,thouzands,hundreds, tens, ones);
   // I/O Signal Definitions
   input  [23:0] number;
	output reg [3:0] milion;
   output reg [3:0] hundredsthouzands;
   output reg [3:0] tenthouzand;
	output reg [3:0] thouzands;
   output reg [3:0] hundreds;
   output reg [3:0] tens;
   output reg [3:0] ones;
 
   // Internal variable for storing bits
   reg [51:0] shift;
   integer i;
 
   always @(number)
   begin
      // Clear previous number and store new number in shift register
      shift[51:24] = 0;
      shift[23:0] = number;
 
      // Loop eight times
      for (i=0; i<24; i=i+1) begin
         if (shift[27:24] >= 5)
            shift[27:24] = shift[27:24] + 3;
 
         if (shift[31:28] >= 5)
            shift[31:28] = shift[31:28] + 3;
 
         if (shift[35:32] >= 5)
            shift[35:32] = shift[35:32] + 3;
			if (shift[39:36] >= 5)
            shift[39:36] = shift[39:36] + 3;
			if (shift[43:40] >= 5)
            shift[43:40] = shift[43:40] + 3;	
			if (shift[47:44] >= 5)
            shift[47:44] = shift[47:44] + 3;	
			if (shift[51:48] >= 5)
            shift[51:48] = shift[51:48] + 3;	
         // Shift entire register left once
         shift = shift << 1;
      end
 
      // Push decimal numbers to output
		milion    = shift[51:48];
		hundredsthouzands =shift[47:44];
		tenthouzand=shift[43:40];
		thouzands = shift[39:36];
      hundreds = shift[35:32];
      tens     = shift[31:28];
      ones     = shift[27:24];
   end
 
endmodule