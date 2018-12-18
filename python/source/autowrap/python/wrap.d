/**
   Functions to wrap entities in D modules for Python consumption.

   These functions are usually not called directly, but from the mixin generated by
   autowrap.python.boilerplate.pydBoilerplate.
 */
module autowrap.python.wrap;

import autowrap.reflection: isUserAggregate, isModule;
import std.meta: allSatisfy;
import std.traits: isArray;


private alias I(alias T) = T;
private enum isString(alias T) = is(typeof(T) == string);

///  Wrap global functions from multiple modules
void wrapAllFunctions(Modules...)() if(allSatisfy!(isModule, Modules)) {
    import autowrap.reflection: AllFunctions;
    import pyd.pyd: def, PyName;

    static foreach(function_; AllFunctions!Modules) {
        static if(__traits(compiles, def!(function_.symbol, PyName!(toSnakeCase(function_.name)))()))
            def!(function_.symbol, PyName!(toSnakeCase(function_.name)))();
        else
            pragma(msg, "\nERROR! Autowrap could not wrap function `", function_.name, "` for Python\n");
    }
}


/// Converts an identifier from camelCase or PascalCase to snake_case.
string toSnakeCase(in string str) @safe pure {

    import std.algorithm: all, map;
    import std.ascii: isUpper;

    if(str.all!isUpper) return str;

    string ret;

    string convert(in size_t index, in char c) {
        import std.ascii: isLower, toLower;

        const prefix = index == 0 ? "" : "_";
        const isHump =
            (index == 0 && c.isUpper) ||
            (index > 0 && c.isUpper && str[index - 1].isLower);

        return isHump ? prefix ~ c.toLower : "" ~ c;
    }

    foreach(i, c; str) {
        ret ~= convert(i, c);
    }

    return ret;
}


@("toSnakeCase empty")
@safe pure unittest {
    static assert("".toSnakeCase == "");
}

@("toSnakeCase no caps")
@safe pure unittest {
    static assert("foo".toSnakeCase == "foo");
}

@("toSnakeCase camelCase")
@safe pure unittest {
    static assert("toSnakeCase".toSnakeCase == "to_snake_case");
}

@("toSnakeCase PascalCase")
@safe pure unittest {
    static assert("PascalCase".toSnakeCase == "pascal_case");
}

@("toSnakeCase ALLCAPS")
@safe pure unittest {
    static assert("ALLCAPS".toSnakeCase == "ALLCAPS");
}


/**
   wrap all aggregates found in the given modules, specified by their name
   (to avoid importing all of them first).

   This function wraps all struct and class definitions, and also all struct and class
   types that are parameters or return types of any functions found.
 */
void wrapAllAggregates(Modules...)() if(allSatisfy!(isModule, Modules)) {

    import autowrap.reflection: AllAggregates, Module;
    import std.meta: staticMap;
    import std.traits: fullyQualifiedName;

    static foreach(aggregate; AllAggregates!Modules) {
        static if(__traits(compiles, wrapAggregate!aggregate))
            wrapAggregate!aggregate;
        else {
            pragma(msg, "\nERROR! Autowrap could not wrap aggregate `", fullyQualifiedName!aggregate, "` for Python\n");
            //wrapAggregate!aggregate; // uncomment to see the error messages from the compiler
        }
    }
}

/**
   Wrap aggregate of type T.
 */
auto wrapAggregate(T)() if(isUserAggregate!T) {

    import autowrap.reflection: Symbol;
    import autowrap.python.pyd.class_wrap: MemberFunction;
    import pyd.pyd: wrap_class, Member, Init;
    import std.meta: staticMap, Filter, AliasSeq;
    import std.traits: Parameters, FieldNameTuple, hasMember;
    import std.typecons: Tuple;

    alias AggMember(string memberName) = Symbol!(T, memberName);
    alias members = staticMap!(AggMember, __traits(allMembers, T));

    alias memberFunctions = Filter!(isMemberFunction, members);

    static if(hasMember!(T, "__ctor"))
        alias constructors = AliasSeq!(__traits(getOverloads, T, "__ctor"));
    else
        alias constructors = AliasSeq!();

    // If we staticMap with std.traits.Parameters, we end up with a collapsed tuple
    // i.e. with one constructor that takes int and another that takes int, string,
    // we'd end up with 3 elements (int, int, string) instead of 2 ((int), (int, string))
    // so we package them up in a std.typecons.Tuple to avoid flattening
    // each being an AliasSeq of types for the constructor
    alias ParametersTuple(alias F) = Tuple!(Parameters!F);

    // A tuple, with as many elements as constructors. Each element is a
    // std.typecons.Tuple of the constructor parameter types.
    alias constructorParamTuples = staticMap!(ParametersTuple, constructors);

    // Apply pyd's Init to the unpacked types of the parameter Tuple.
    alias InitTuple(alias Tuple) = Init!(Tuple.Types);

    enum isPublic(string fieldName) = __traits(getProtection, __traits(getMember, T, fieldName)) == "public";
    alias publicFields = Filter!(isPublic, FieldNameTuple!T);

    wrap_class!(
        T,
        staticMap!(Member, publicFields),
        staticMap!(MemberFunction, memberFunctions),
        staticMap!(InitTuple, constructorParamTuples),
   );
}


// must be a global template
private template isMemberFunction(A...) if(A.length == 1) {
    alias T = A[0];
    static if(__traits(compiles, __traits(identifier, T)))
        enum isMemberFunction = isPublicFunction!T && __traits(identifier, T) != "__ctor";
    else
        enum isMemberFunction = false;
}


private template isPublicFunction(alias F) {
    import std.traits: isFunction;
    enum prot = __traits(getProtection, F);
    enum isPublicFunction = isFunction!F && (prot == "export" || prot == "public");
}
