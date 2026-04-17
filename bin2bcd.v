module bin2bcd(bin,bcd_ten,bcd_one);
input [3:0] bin;
output reg[3:0] bcd_ten;
output reg[3:0] bcd_one;
always @(*)
begin
	bcd_ten = bin / 4'd10;
	bcd_one = bin % 4'd10;
end
endmodule
	