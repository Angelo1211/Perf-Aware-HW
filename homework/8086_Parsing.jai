
OP_Codes :: enum u8
{
    // 4 bit OP_CODES
    mov_immediate_to_register                       :: 0b1011;

    // 6 bit OP_CODES
    mov_register_or_memory_to_register_or_memory    :: 0b100010;
    mov_immediate_to_register_or_memory             :: 0b110001;
}

MOD_Encoding :: enum u8
{
    MEMORY_MODE_NO_DISPLACEMENT   :: 0b00;
    MEMORY_MODE_08_DISPLACEMENT   :: 0b01;
    MEMORY_MODE_16_DISPLACEMENT   :: 0b10;
    REGISTER_MODE_NO_DISPLACEMENT :: 0b11;
}

REG_Encoding :: enum u8
{
    // Byte
    al;cl;dl;bl;
    ah;ch;dh;bh;

    // Wide
    ax;cx;dx;bx;
    sp;bp;si;di;
}
REGISTER_WIDE_OFFSET :: REG_Encoding.ax;

Effective_Address_Encodings :: [2] string.[
    string.["bx", "si"],
    string.["bx", "di"],

    string.["bp", "si"],
    string.["bp", "di"],

    string.["si", ""],
    string.["di", ""],

    string.["bp", ""], // When MEMORY_MODE_NO_DISPLACEMENT is true this is a Direct Address
    string.["bx", ""],
];

get :: inline (bytes : *[]u8) -> u8
{
    return ifx bytes.count > 0 then <<bytes.data else 0;
}

advance :: inline (bytes : *[]u8, amount := 1)
{
    assert(amount >= 0);
    assert(bytes.count >= amount);

    bytes.data  += amount;
    bytes.count -= amount;
}

sign_extend :: inline (x : u16, bit_count :int) -> u16
{
	// If the most significant bit is set and we're parsing two's complement
	// data, then we're looking at a negative number. Extend by adding ones.
	if x >> (bit_count - 1) & 1
		x |= cast,trunc(u16) (0xFFFF << bit_count);

	return x;
}