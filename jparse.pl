#!/usr/bin/env perl

use Modern::Perl;

use Marpa::XS;
use Data::Dumper;

my @tokens1 = (
    ['OPEN_CURLY'],

    ['STRING' => 'asdf'],
    ['COLON'],
    ['STRING' => 'qwer'],

    ['COMMA'],

    ['STRING' => 'ZCXV'],
    ['COLON'],
    ['STRING' => 'VNMB'],

    ['COMMA'],

    ['STRING' => 'ZCXV'],
    ['COLON'],
    ['OPEN_CURLY'],
    ['STRING' => 'inner1'],
    ['COLON'],
    ['STRING' => 'innerA'],
    ['CLOSE_CURLY'],

    ['CLOSE_CURLY'],
);

my @tokens2 = (
    ['OPEN_BRACKET'],
    ['STRING' => 'A'],
    ['COMMA'],
    ['STRING' => 'B'],
    ['COMMA'],
    ['STRING' => 'C'],
    ['COMMA'],
    ['STRING' => 'D'],
    ['CLOSE_BRACKET'],
);

my @tokens = @tokens2;

my $grammar = Marpa::XS::Grammar->new({
    start => 'json',
    actions => 'main',
    default_action => 'do_default',
    terminals => [qw(
        OPEN_CURLY CLOSE_CURLY
        OPEN_BRACKET CLOSE_BRACKET
        COMMA COLON
        STRING
    )],
    rules => [
        ### Root
        {
            lhs => 'json',
            rhs => [qw(some_data)],
        },

        ### Top level
        {
            lhs => 'some_data',
            rhs => [qw(array)],
        },
        {
            lhs => 'some_data',
            rhs => [qw(hash)],
        },
        {
            lhs => 'some_data',
            rhs => [qw(string)],
        },

        ### Arrays
        {
            lhs => 'array',
            rhs => [qw(OPEN_BRACKET array_elements CLOSE_BRACKET)],
        },
        {
            lhs => 'array_elements',
            rhs => [qw(array_element COMMA array_elements)],
        },
        {
            lhs => 'array_elements',
            rhs => [qw(array_element)],
        },
        {
            lhs => 'array_element',
            rhs => [qw(some_data)],
        },

        ### Hashes
        {
            lhs => 'hash',
            rhs => [qw(OPEN_CURLY key_value_pairs CLOSE_CURLY)],
        },
        {
            lhs => 'key_value_pairs',
            rhs => [qw(key_value_pair COMMA key_value_pairs)],
        },
        {
            lhs => 'key_value_pairs',
            rhs => [qw(key_value_pair)],
        },
        {
            lhs => 'key_value_pair',
            rhs => [qw(STRING COLON some_data)],
        },

        ### Strings
        {
            lhs => 'string',
            rhs => [qw(STRING)],
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

my $output = $rec->value;
say Data::Dumper->Dump([$output], ['final']);
say $$output->[1];

sub do_default {
    say Data::Dumper->Dump([ [@_] ],[ 'default' ]);
    return $_[1];
}

sub key_value_pair {
    say Data::Dumper->Dump([ [@_] ],[ 'key_value_pair' ]);
    return {$_[1] => $_[3]};
}

sub array {
    say Data::Dumper->Dump([ [@_] ],[ 'array' ]);
    return $_[2];
}

sub array_elements {
    say Data::Dumper->Dump([ [@_] ],[ 'array_elements' ]);
    my @a = map {$_} $_[1], @{$_[3]};
    return \@a;
}

sub array_element {
    #say Data::Dumper->Dump([ [@_] ],[ 'array_element' ]);
#    say "array_element:$_[1]";
    return $_[1];
}

sub some_data {
    say Data::Dumper->Dump([ [@_] ],[ 'some_data' ]);
    return $_[1];
}

sub string {
    say "string:$_[1]";
    return $_[1];
}

sub json {
    say Data::Dumper->Dump([ [@_] ],[ 'json' ]);
    return $_[1];
}
