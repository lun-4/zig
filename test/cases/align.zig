const assert = @import("std").debug.assert;

var foo: u8 align 4 = 100;

test "global variable alignment" {
    assert(@typeOf(&foo) == &align 4 u8);
    const slice = (&foo)[0..1];
    assert(@typeOf(slice) == []align 4 u8);
}

fn derp() align (@sizeOf(usize) * 2) -> i32 { 1234 }
fn noop1() align 1 {}
fn noop4() align 4 {}

test "function alignment" {
    assert(derp() == 1234);
    assert(@typeOf(noop1) == fn() align 1);
    assert(@typeOf(noop4) == fn() align 4);
    noop1();
    noop4();
}


var baz: packed struct {
    a: u32,
    b: u32,
} = undefined;

test "packed struct alignment" {
    assert(@typeOf(&baz.b) == &align 1 u32);
}


const blah: packed struct {
    a: u3,
    b: u3,
    c: u2,
} = undefined;

test "bit field alignment" {
    assert(@typeOf(&blah.b) == &align 1:3:6 const u3);
}

test "default alignment allows unspecified in type syntax" {
    assert(&u32 == &align @alignOf(u32) u32);
}

test "implicitly decreasing pointer alignment" {
    const a: u32 align 4 = 3;
    const b: u32 align 8 = 4;
    assert(addUnaligned(&a, &b) == 7);
}

fn addUnaligned(a: &align 1 const u32, b: &align 1 const u32) -> u32 { *a + *b }

test "implicitly decreasing slice alignment" {
    const a: u32 align 4 = 3;
    const b: u32 align 8 = 4;
    assert(addUnalignedSlice((&a)[0..1], (&b)[0..1]) == 7);
}
fn addUnalignedSlice(a: []align 1 const u32, b: []align 1 const u32) -> u32 { a[0] + b[0] }

test "specifying alignment allows pointer cast" {
    testBytesAlign(0x33);
}
fn testBytesAlign(b: u8) {
    var bytes align 4 = []u8{b, b, b, b};
    const ptr = @ptrCast(&u32, &bytes[0]);
    assert(*ptr == 0x33333333);
}

test "specifying alignment allows slice cast" {
    testBytesAlignSlice(0x33);
}
fn testBytesAlignSlice(b: u8) {
    var bytes align 4 = []u8{b, b, b, b};
    const slice = ([]u32)(bytes[0..]);
    assert(slice[0] == 0x33333333);
}

test "@alignCast pointers" {
    var x: u32 align 4 = 1;
    expectsOnly1(&x);
    assert(x == 2);
}
fn expectsOnly1(x: &align 1 u32) {
    expects4(@alignCast(4, x));
}
fn expects4(x: &align 4 u32) {
    *x += 1;
}

test "@alignCast slices" {
    var array align 4 = []u32{1, 1};
    const slice = array[0..];
    sliceExpectsOnly1(slice);
    assert(slice[0] == 2);
}
fn sliceExpectsOnly1(slice: []align 1 u32) {
    sliceExpects4(@alignCast(4, slice));
}
fn sliceExpects4(slice: []align 4 u32) {
    slice[0] += 1;
}


test "implicitly decreasing fn alignment" {
    testImplicitlyDecreaseFnAlign(alignedSmall, 1234);
    testImplicitlyDecreaseFnAlign(alignedBig, 5678);
}

fn testImplicitlyDecreaseFnAlign(ptr: fn () align 1 -> i32, answer: i32) {
    assert(ptr() == answer);
}

fn alignedSmall() align 8 -> i32 { 1234 }
fn alignedBig() align 16 -> i32 { 5678 }


test "@alignCast functions" {
    assert(fnExpectsOnly1(simple4) == 0x19);
}
fn fnExpectsOnly1(ptr: fn()align 1 -> i32) -> i32 {
    fnExpects4(@alignCast(4, ptr))
}
fn fnExpects4(ptr: fn()align 4 -> i32) -> i32 {
    ptr()
}
fn simple4() align 4 -> i32 { 0x19 }


test "generic function with align param" {
    assert(whyWouldYouEverDoThis(1) == 0x1);
    assert(whyWouldYouEverDoThis(4) == 0x1);
    assert(whyWouldYouEverDoThis(8) == 0x1);
}

fn whyWouldYouEverDoThis(comptime align_bytes: u8) align align_bytes -> u8 { 0x1 }
