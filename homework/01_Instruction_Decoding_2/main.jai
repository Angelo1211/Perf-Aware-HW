#import "Basic";
#import "File";
#import "String";

#load "../8086_Parsing.jai";

FILES :: string.[
    // "../data/listing_0037_single_register_mov",
    // "../data/listing_0038_many_register_mov",
    "../data/listing_0039_more_movs",
    // "../data/listing_0040_challenge_movs",
];

main :: ()
{
    builder :String_Builder;
    init_string_builder(*builder);

    for f : FILES
    {
        file_data, success := read_entire_file(f);
        if !success then return;
        defer free(file_data);

        print_to_builder(*builder, "// Original File: %\n\nbits 16\n\n", path_filename(f));

        output_string :string;
        instruction_stream := cast([]u8)file_data;
        while instruction_stream.count > 0
        {
            byte0 := get(*instruction_stream);
            op_code, op_code_name := decode_op_code(byte0);

            // All instructions take at least 2 bytes AFAIK, safe to advance
            advance(*instruction_stream);
            byte1 := get(*instruction_stream);

            if op_code == 
            {
                case .mov_register_to_register;
                {
                    d_flag := cast(bool) byte0 & 0b10;
                    w_flag := cast(bool) byte0 & 0b01;

                    mod := cast(MOD_Encoding) ((byte1 >> 6) & 0b011);
                    reg :=                    ((byte1 >> 3) & 0b111);
                    r_m :=                    ((byte1 >> 0) & 0b111);

                    if mod == 
                    {
                        // Register to register MOV
                        case .REGISTER_MODE_NO_DISPLACEMENT;
                        {
                            dst := cast(REG_Encoding) ifx d_flag then reg else r_m;
                            dst += ifx w_flag then REGISTER_WIDE_OFFSET;

                            src := cast(REG_Encoding) ifx d_flag then r_m else reg;
                            src += ifx w_flag then REGISTER_WIDE_OFFSET;

                            output_string = tprint("% %, %\n", op_code_name, dst, src);
                        }
                        case;assert(false);
                    }
                }

                case .mov_immediate_to_register;
                {
                    w_flag := cast(bool) ((byte0 >> 3) & 0b001);
                    reg    :=            ((byte0 >> 0) & 0b111);
                    dst := cast(REG_Encoding) reg;
                    dst += ifx w_flag then REGISTER_WIDE_OFFSET;

                    data :u16= byte1;

                    if w_flag
                    {
                        advance(*instruction_stream);
                        data_hi :u16= get(*instruction_stream);
                        data |= data_hi << 8;
                    }
                    else
                        data = sign_extend(data, 8);

                    output_string = tprint("% %, %\n", op_code_name, dst, data);
                }
                case;assert(false);
            }

            append(*builder, output_string);
            print("%", output_string);
            advance(*instruction_stream);
        }
        print("\n\n");

        // output_file_name := tprint("data/%_disassembled.asm", path_filename(f));
        // success = write_entire_file(output_file_name, *builder, true);
        // if !success then return;
    }
}

decode_op_code :: inline (byte : u8) -> OP_Codes, string
{
    // Check the 4 bit opcodes first
    // TODO(AO) check if you're less than the largest 4 bit opcodes
    op_code := cast(OP_Codes) byte >> 4;

    // If it isn't a 4 bit opcode try the 6 bit ones
    if op_code != .mov_immediate_to_register
    {
        op_code =  cast(OP_Codes) byte >> 2;

        if op_code == 
        {
            // We actually don't do anything here, we only want to assert 
            // if we encounter an unrecognized opcode
            case .mov_register_to_register;
            case .mov_immediate_to_register_or_memory;
            
            // Unrecognized opcode
            case;assert(false);
        }
    }

    // TODO(AO) There probably should be a table for this instead
    success, enum_name := split_from_left(tprint("%", op_code), #char "_");

    return op_code, enum_name;
}