
OP_Codes :: enum u8
{
    mov :: 0b100010;
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

get :: inline (bytes : *[]u8) -> u8
{
    return ifx bytes.count > 0 then <<bytes.data else 0;
}

advance :: inline (bytes : *[]u8, amount := 1) -> u8
{
    assert(amount >= 0);
    assert(bytes.count >= amount);

    bytes.data  += amount;
    bytes.count -= amount;

    return get(bytes);
}