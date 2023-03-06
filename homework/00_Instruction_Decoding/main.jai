#import "Basic";
#import "File";
#import "String";

#load "../8086_Parsing.jai";

FILES :: string.[
    "../data/listing_0037_single_register_mov",
    "../data/listing_0038_many_register_mov",
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
                    byte := advance(*instruction_stream);

                    mod := cast(MOD_Encoding) ((byte >> 6) & 0b011);
                    reg :=                    ((byte >> 3) & 0b111);
                    r_m :=                    ((byte >> 0) & 0b111);

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
