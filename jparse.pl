#!/usr/bin/env perl

use Modern::Perl;

use Marpa::XS;
use Data::Dumper;

my @tokens = (
    ['OPEN_CURLY'],
    ['STRING' => 'asdf'],
    ['CLOSE_CURLY'],
);

my $grammar = Marpa::XS::Grammar->new({
    start => 'json',
    actions => 'main',
    default_action => 'do_default',
    terminals => [qw(
        OPEN_CURLY CLOSE_CURLY STRING
    )],
    rules => [
        {
            lhs => 'json',
            rhs => [qw(OPEN_CURLY STRING CLOSE_CURLY)]
        },
    ],
});

$grammar->precompute;

my $rec = Marpa::XS::Recognizer->new( { grammar => $grammar } );
foreach my $token (@tokens) {
    if (defined $rec->read( @$token )) {
        say "reading Token: @$token";
    } else {
        die "Error reading Token: @$token";
    };
}

say Data::Dumper->Dump([$rec->value], ['value']);

sub do_default {
    say Data::Dumper->Dump([ [@_] ],[ 'default' ]);
    return;
}
