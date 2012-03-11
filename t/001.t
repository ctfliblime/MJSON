#!/usr/bin/env perl

use 5.14.0;

use Test::More;

BEGIN {use_ok 'MJSON';}

my $log = Log::Dispatch->new(
    outputs => [
        [ 'Screen', min_level => 'notice', newline => 1, stderr => 0 ],
    ],
);

my $m = MJSON->new(log => $log);
isa_ok $m, 'MJSON';

my $output = $m->parse(q/{ "a" : "b", "c" : false, "d" : ["q","w"] }/);
is ref $output, 'HASH';

done_testing;
