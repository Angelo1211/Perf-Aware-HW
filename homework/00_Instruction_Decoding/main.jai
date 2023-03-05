#import "Basic";
#import "File";
#import "String";

// If you don't have these, it's likely that you haven't assembled the corresponding .asm files
// I used https://www.nasm.us/ for that.
FILES :: string.[
    "data/listing_0037_single_register_mov",
    "data/listing_0038_many_register_mov",
];

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


main :: ()
{
    builder :String_Builder;
    init_string_builder(*builder);

    for f : FILES
    {
        file_data, success := read_entire_file(f);
        if !success then return;
        defer free(file_data);

        print_to_builder(*builder, "// Original File: %\n\n", path_filename(f));
        append(*builder, "bits 16\n\n");

        instruction_stream := cast([]u8)file_data;
        while instruction_stream.count > 0
        {
            instruction := get(*instruction_stream);

            op_code  := cast(OP_Codes) instruction >> 2;
            d_flag   := cast(bool)     instruction & 0b10;
            w_flag   := cast(bool)     instruction & 0b01;

            if op_code == 
            {
                case .mov;
                {
                    advance(*instruction_stream);
                    byte := get(*instruction_stream);

                    mod := cast(MOD_Encoding) ((byte >> 6) & 0b011);
                    r_m :=                    ((byte >> 0) & 0b111);
                    reg :=                    ((byte >> 3) & 0b111);

                    if mod == 
                    {
                        // Register to register MOV
                        case .REGISTER_MODE_NO_DISPLACEMENT;
                        {
                            dst := cast(REG_Encoding) ifx d_flag then reg else r_m;
                            dst += ifx w_flag then REGISTER_WIDE_OFFSET;

                            src := cast(REG_Encoding) ifx d_flag then r_m else reg;
                            src += ifx w_flag then REGISTER_WIDE_OFFSET;

                            print_to_builder(*builder, "% %, %\n", op_code, dst, src);
                        }

                        case;
                         assert(false);
                    }
                }

                case;
                    assert(false);
            }

            advance(*instruction_stream);
        }

        output_file_name := tprint("data/disassembled_%.asm", path_filename(f));
        success = write_entire_file(output_file_name, *builder, true);
        if !success then return;
    }
}

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
