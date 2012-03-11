#!/usr/bin/env perl

use 5.14.0;
use MJSON;
use Test::More;
use Test::Exception;

my @tests = (
q/[
"q",
null,
"w",
{"A" : "B", "C" : "D",
"e
",
false,
true,
"r"
]
/,
q/
[
"q",
null,
"w",
{"A" : "B", "1", "C" : "D"}
"e
",
false,
true,
"r"
]
/,
);

my $m = MJSON->new;
isa_ok $m, 'MJSON';

for my $test (@tests) {
    dies_ok { MJSON->new->parse($test) };
}

done_testing;
