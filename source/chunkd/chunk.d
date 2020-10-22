/++
    A module for creating chunks. You can put any data in it, and compress, 
    and extract the very chunks from files. It will be useful for storing 
    some kind of data about maps, textures or the like.

    ---
    Chunk chunk = Chunk("Simple chunk", "Hello, World! It's Chunk!");
    std.file.write("binary",chunk.save());
    ---

    Authors: TodNaz
    License: MIT
+/
module chunkd.chunk;

import std.zlib;

private ubyte[4] toByte(T)(T value) @trusted
{
    ubyte[4] ab;
    for (int i = 0; i < 4; i++)
        ab[3 - i] = cast(ubyte) (value >> (i * 8));

    return ab;
}

private T byteTo(T)(ubyte[] bytes) @trusted
{
    T data = T.init;
    foreach(i; 0 .. bytes.length) data |= cast(T) ((data << 8) + bytes[i]);

    return data;
}

/++
    Chunk structure. Has a title and information. The size of the chunk, the size 
    of the name, then the name itself and the data are written to the file, and 
    so on in order.
+/
struct Chunk
{
    public
    {
        string name; /// Chunk name
        ubyte[] data; /// Chunk data
    }

    /++
        Creates a chunk.

        Params:
            name = Chunk name.
            data = Chunk data.
    +/
    this(string name,ubyte[] data) @safe
    {
        this.name = name;
        this.data = data;
    }

    /// ditto
    this(string name,string data) @trusted
    {
        this.name = name;
        this.data = cast(ubyte[]) data;
    }

    ///
    public string toString() @trusted
    {
        return "Chunk(\""~name~"\",\""~(cast(string) data)~"\")";
    }

    /++
        Compresses data. They are extremely effective only in large quantities.
    +/
    public Chunk compress() @trusted
    {
        data = std.zlib.compress(cast(void[]) data);

        return this;
    }

    /++
        Decompress data if it has been compressed.
    +/
    public Chunk uncompress() @trusted
    {
        data = cast(ubyte[]) std.zlib.uncompress(cast(void[]) data, 0u, HeaderFormat.deflate);

        return this;
    }

    /++
        Gives the size of the data.
    +/
    public size_t size() @safe
    {
        return data.length * ubyte.sizeof;
    }

    /++
        Gives exhaust in the form of bytes, where you can write to a file, 
        from where, in the future, you can parse chunks.
    +/
    public ubyte[] save() @trusted
    {
        return size().toByte ~ (name.length * ubyte.sizeof).toByte ~ (cast(ubyte[]) name) ~ data;
    }

    /++
        Retrieves chunks from file data or other information storage location

        Params:
            data = Data.
    +/
    public static Chunk[] parse(ubyte[] data) @trusted
    {
        Chunk[] chunks;

        size_t i = 0;
        size_t lenName;
        size_t lenData;
        string _name;
        ubyte[] _data;

        while(i < data.length) {
            lenData = byteTo!size_t(data[i .. i + 4])     / ubyte.sizeof;
            lenName = byteTo!size_t(data[i + 4 .. i + 8]) / ubyte.sizeof;

            _name = cast(string) data[i + 8 .. i + 8 + lenName];
            _data = data[i + 8 + lenName .. i + 8 + lenName + lenData];

            chunks ~= Chunk(_name,_data);

            i = i + 8 + lenName + lenData;
        }

        return chunks;
    }
}

@("Chunk test") @safe
unittest
{
    Chunk chunk = Chunk("Simple", "Hello, World!");

    ubyte[] data = chunk.save();

    assert(Chunk.parse(data)[0] == chunk);
}

@("Chunk compress") @safe
unittest
{
    Chunk chunk = Chunk("Test","
        MIT License

        Permission is hereby granted, free of charge, to any person obtaining a copy of 
        this software and associated documentation files (the \"Software\"), to deal in the 
        Software without restriction, including without limitation the rights to use, copy, 
        modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
        and to permit persons to whom the Software is furnished to do so, subject to the 
        following conditions:

        The above copyright notice and this permission notice shall be included in all copies 
        or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
        INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
        PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
        FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
        OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
        OTHER DEALINGS IN THE SOFTWARE.

        ...");

    chunk.compress();

    ubyte[] data = chunk.save();

    chunk.uncompress();

    assert(Chunk.parse(data)[0].uncompress() == chunk);
}