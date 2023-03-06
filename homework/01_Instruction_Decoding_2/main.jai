#import "Basic";
#import "File";
#import "String";

#load "../8086_Parsing.jai";

FILES :: string.[
    "../data/listing_0037_single_register_mov",
    "../data/listing_0038_many_register_mov",
    "../data/listing_0039_more_movs",
    "../data/listing_0040_challenge_movs",
];

// TODO(AO) Draw the rest of the fucking Owl

main :: ()
{
    // builder :String_Builder;
    // init_string_builder(*builder);

    for f : FILES
    {
        file_data, success := read_entire_file(f);
        if !success then return;
        defer free(file_data);

        // print_to_builder(*builder, "// Original File: %\n\nbits 16\n\n", path_filename(f));

        instruction_stream := cast([]u8)file_data;
        while instruction_stream.count > 0
        {
            print("%\t", advance(*instruction_stream));
        }
        print("\n");

        // output_file_name := tprint("data/disassembled_%.asm", path_filename(f));
        // success = write_entire_file(output_file_name, *builder, true);
        // if !success then return;
    }
}