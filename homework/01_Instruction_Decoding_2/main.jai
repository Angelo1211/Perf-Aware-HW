#import "Basic";
#import "File";
#import "String";
#import "Math";

#load "../8086_Parsing.jai";

FILES :: string.[
    "../data/listing_0037_single_register_mov",
    "../data/listing_0038_many_register_mov",
    "../data/listing_0039_more_movs",
    "../data/listing_0040_challenge_movs",
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
                // NOTE(AO) This is very similar to mov_register_or_memory_to_register_or_memory, there is
                //          probably a way to de-duplicate all of this, but it's probably not worth it
                case .mov_immediate_to_register_or_memory;
                {
                    w_flag := cast(bool) byte0 & 0b01;

                    mod := cast(MOD_Encoding) ((byte1 >> 6) & 0b011);
                    r_m := cast(REG_Encoding) ((byte1 >> 0) & 0b111);

                    if mod ==
                    {
                        // Memory / register to memory / register
                        case .MEMORY_MODE_NO_DISPLACEMENT; #through;
                        case .MEMORY_MODE_08_DISPLACEMENT; #through;
                        case .MEMORY_MODE_16_DISPLACEMENT;
                        {
                            effective_address : string;
                            if mod == .MEMORY_MODE_NO_DISPLACEMENT
                            {
                                if r_m != 0b110
                                {
                                    effective_address = calculate_effective_address( xx r_m);
                                }
                                else
                                {
                                    // There can be displacement bytes if we're doing direct addressing
                                    disp0 := advance(*instruction_stream);
                                    disp1 := ifx w_flag then advance(*instruction_stream);
                                    data  := decode_displacement(disp0, disp1);

                                    effective_address = tprint("[%]", cast,no_check(s16)data);
                                }
                            }
                            else
                            {
                                disp0 := advance(*instruction_stream);
                                disp1 := ifx w_flag then advance(*instruction_stream);
                                disp  := decode_displacement(disp0, disp1);

                                effective_address = calculate_effective_address(xx r_m, disp);
                            }

                            data0 := advance(*instruction_stream);
                            data1 := ifx w_flag then advance(*instruction_stream);
                            data  := decode_displacement(data0, data1);

                            explicit_size_string := tprint("% %", ifx w_flag then "word" else "byte", data);

                            output_string = tprint("% %, %\n", op_code_name, effective_address, explicit_size_string);
                        }

                        // TODO what about Register mode MOVs??
                        case;assert(false);
                    }
                }

                case .mov_register_or_memory_to_register_or_memory;
                {
                    d_flag := cast(bool) byte0 & 0b10;
                    w_flag := cast(bool) byte0 & 0b01;

                    mod := cast(MOD_Encoding) ((byte1 >> 6) & 0b011);
                    reg := cast(REG_Encoding) ((byte1 >> 3) & 0b111);
                    r_m := cast(REG_Encoding) ((byte1 >> 0) & 0b111);

                    if mod == 
                    {
                        // Memory / register to memory / register
                        case .MEMORY_MODE_NO_DISPLACEMENT; #through;
                        case .MEMORY_MODE_08_DISPLACEMENT; #through;
                        case .MEMORY_MODE_16_DISPLACEMENT;
                        {
                            effective_address : string;
                            if mod == .MEMORY_MODE_NO_DISPLACEMENT
                            {
                                if r_m != 0b110
                                {
                                    effective_address = calculate_effective_address( xx r_m);
                                }
                                else
                                {
                                    // There can be displacement bytes if we're doing direct addressing
                                    disp0 := advance(*instruction_stream);
                                    disp1 := ifx w_flag then advance(*instruction_stream);
                                    data  := decode_displacement(disp0, disp1);

                                    effective_address = tprint("[%]", cast,no_check(s16)data);
                                }
                            }
                            else
                            {
                                disp0 := advance(*instruction_stream);
                                disp1 := ifx mod == .MEMORY_MODE_16_DISPLACEMENT then advance(*instruction_stream);
                                disp  := decode_displacement(disp0, disp1);

                                effective_address = calculate_effective_address(xx r_m, disp);
                            }

                            reg += ifx w_flag then REGISTER_WIDE_OFFSET;

                            if d_flag
                                output_string = tprint("% %, %\n", op_code_name, reg, effective_address);
                            else
                                output_string = tprint("% %, %\n", op_code_name, effective_address, reg);
                        }
                        // Register to register MOV
                        case .REGISTER_MODE_NO_DISPLACEMENT;
                        {
                            dst := ifx d_flag then reg else r_m;
                            dst += ifx w_flag then REGISTER_WIDE_OFFSET;

                            src := ifx d_flag then r_m else reg;
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

                    data0 := byte1;
                    data1 := ifx w_flag then advance(*instruction_stream);
                    data  := decode_displacement(data0, data1);

                    output_string = tprint("% %, %\n", op_code_name, dst, data);
                }

                case .mov_memory_to_accumulator; #through;
                case .mov_accumulator_to_memory;
                {
                    w_flag := cast(bool) ((byte0 >> 0) & 0b1);
                    write  := cast(bool) ((byte0 >> 1) & 0b1);
                    reg    := REG_Encoding.al + ifx w_flag then REGISTER_WIDE_OFFSET;

                    disp0 := byte1;
                    disp1 := ifx w_flag then advance(*instruction_stream);
                    data  := decode_displacement(disp0, disp1);

                    if write
                        output_string = tprint("% [%], %\n", op_code_name, data, reg);
                    else
                        output_string = tprint("% %, [%]\n", op_code_name, reg, data);
                }

                case;assert(false);
            }

            append(*builder, output_string);
            print("%", output_string);
            advance(*instruction_stream);
        }
        print("\n\n");

        output_file_name := tprint("../data/%_disassembled.asm", path_filename(f));
        success = write_entire_file(output_file_name, *builder, true);
        if !success then return;
    }
}

decode_displacement :: (byte0 : u8, byte1 : u8 =0 ) -> u16
{
    data :u16= byte0;

    if byte1
    {
        data_hi :u16= byte1;
        data |= data_hi << 8;
    }
    else
    {
        data = sign_extend(data, 8);
    }

    return data;
}

// TODO(AO) Maybe the string builder is better suited for this?
calculate_effective_address :: (r_m : u8, dis : u16 = 0) -> string
{
    effective_address_components := Effective_Address_Encodings[r_m];

    effective_address := tprint("[%", effective_address_components[0]);

    if effective_address_components[1]
        effective_address = tprint("% + %", effective_address, effective_address_components[1]);
    
    if dis != 0
    {
        disp := cast, no_check(s16) dis;
        sign := ifx disp > 0 then "+" else "-";
        effective_address = tprint("% % %", effective_address, sign, abs(disp));
    }

    effective_address = tprint("%]", effective_address);

    return effective_address;
}

decode_op_code :: inline (byte : u8) -> OP_Codes, string
{
    // Check the 4 bit opcodes first
    op_code := cast(OP_Codes) byte >> 4;

    if op_code ==
    {
        // We don't do anything inside any of the known cases
        // We're just working our way down the variable width
        // opcodes until we either find a valid one or assert
        case .mov_immediate_to_register;

        // If it isn't a 4 bit opcode try 6 bits
        case;
        {
            op_code = cast(OP_Codes) byte >> 2;

            if op_code == 
            {
                case .mov_register_or_memory_to_register_or_memory;
                case .mov_immediate_to_register_or_memory;
                
                // Not a 6 bit Opcode, try 7 bit ones
                case;
                {
                    op_code = cast(OP_Codes) byte >> 1;
                    if op_code ==
                    {
                        case .mov_memory_to_accumulator;
                        case .mov_accumulator_to_memory;

                        // Unrecognized opcode
                        case;assert(false);
                    }
                }
            }
        }
    }

    // TODO(AO) There probably should be a table for this instead
    success, enum_name := split_from_left(tprint("%", op_code), #char "_");

    return op_code, enum_name;
}