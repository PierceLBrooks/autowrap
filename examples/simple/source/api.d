import std.datetime: DateTime;

export auto createIntPoint(int x, int y) {
    import templates: Point;
    return Point!int(x, y);
}

export auto createIntString(int i, string s) {
    import structs: IntString;
    return IntString(i, s);
}

export auto createOuter(double x, double y, double value, string string1, string string2) {
    import templates;
    import structs: String;
    return Outer!double([
                            Inner1!double(Point!double(x, y), value),
                            Inner1!double(Point!double(x, y), value + 1),
                        ],
                        Inner2!double(EvenInner!double(value)),
                        String(string1),
                        String(string2));
}

export auto createOuters(double x, double y, double value, string string1, string string2) {
    import templates;
    import structs: String;
    return [Outer!double([
                             Inner1!double(Point!double(x, y), value),
                             Inner1!double(Point!double(x, y), value + 2)
                         ],
                        Inner2!double(EvenInner!double(value)),
                        String(string1),
                        String(string2))];
}


export DateTime createDateTime(int year, int month, int day) {
    return DateTime(year, month, day);
}

export DateTime[][] dateTimeArray(int year, int month, int day) {
    return [[DateTime(year, month, day)]];
}


export auto points(int length, int x, int y) {
    import non_wrapped_structs: AnotherPoint;
    import std.range: iota;
    import std.array: array;
    import std.algorithm: map;
    return [length.iota.map!(a => AnotherPoint(x, y)).array];
}

export auto tupleOfDateTimes(int year, int month, int day) {
    import std.typecons: tuple;
    return tuple([DateTime(year, month, day)], [DateTime(year + 1, month + 1, day + 1)]);
}

// to make sure there is no attempt to wrap this
private int shouldNotBeAProblem(int i, int j) {
    return i + j;
}
