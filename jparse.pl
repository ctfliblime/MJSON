#!/usr/bin/env perl

use Modern::Perl;

use Marpa::XS;
use Log::Dispatch;
use Data::Dumper;

our $log = Log::Dispatch->new(
    outputs => [
        [ 'Screen', min_level => 'notice', newline => 1 ],
    ],
);

my $json1 = <<EOF;
[
"q",
"w",
{"A" : "B", "C" : "D"},
"e
",
"r"
]
EOF

my $json2 = q{"A\"B"};

my $json3 = <<EOF;
{
    "glossary": {
        "title": "example glossary",
        "GlossDiv": {
            "title": "S",
            "GlossList": {
                "GlossEntry": {
                    "ID": "SGML",
                    "SortAs": "SGML",
                    "GlossTerm": "Standard Generalized Markup Language",
                    "Acronym": "SGML",
                    "Abbrev": "ISO 8879:1986",
                    "GlossDef": {
                        "para": "A meta-markup language, used to create markup languages such as DocBook.",
                        "GlossSeeAlso": ["GML", "XML"]
                    },
                    "GlossSee": "markup"
                }
            }
        }
    }
}
EOF

my $json4 = <<EOF;
{"menu": {
    "header": "SVG Viewer",
    "items": [
        {"id": "Open"},
        {"id": "OpenNew", "label": "Open New"},
        null,
        {"id": "ZoomIn", "label": "Zoom In"},
        {"id": "ZoomOut", "label": "Zoom Out"},
        {"id": "OriginalView", "label": "Original View"},
        null,
        {"id": "Quality"},
        {"id": "Pause"},
        {"id": "Mute"},
        null,
        {"id": "Find", "label": "Find..."},
        {"id": "FindAgain", "label": "Find Again"},
        {"id": "Copy"},
        {"id": "CopyAgain", "label": "Copy Again"},
        {"id": "CopySVG", "label": "Copy SVG"},
        {"id": "ViewSVG", "label": "View SVG"},
        {"id": "ViewSource", "label": "View Source"},
        {"id": "SaveAs", "label": "Save As"},
        null,
        {"id": "Help"},
        {"id": "About", "label": "About Adobe CVG Viewer..."}
    ]
}}
EOF

sub token_itr {
    my $json = shift;

    return sub {
        TOKEN: {
            return ['COMMA']           if $json =~ /\G ,        /gcx;
            return ['COLON']           if $json =~ /\G :        /gcx;
            return ['OPEN_BRACKET']    if $json =~ /\G \[       /gcx;
            return ['CLOSE_BRACKET']   if $json =~ /\G \]       /gcx;
            return ['OPEN_CURLY']      if $json =~ /\G {        /gcx;
            return ['CLOSE_CURLY']     if $json =~ /\G }        /gcx;
            return ['STRING' => $1]    if $json =~ /\G "([^"]*)"/gcx;
            return ['NULL']            if $json =~ /\G null     /gcx;
            redo TOKEN                 if $json =~ /\G \s+      /gcx;
            return undef;
        }
    };
}

sub tokenize {
    my $json = shift;
    my $itr = token_itr($json);
    my @tokens;

    my $t;
    push @tokens, $t while ($t = $itr->());
    return @tokens;
}

my @tokens = tokenize($json4);

$log->info(Dumper \@tokens);

my $grammar = Marpa::XS::Grammar->new({
    start => 'json',
    actions => 'main',
    default_action => 'do_default',
    terminals => [qw(
        OPEN_CURLY CLOSE_CURLY
        OPEN_BRACKET CLOSE_BRACKET
        COMMA COLON
        STRING NULL
    )],
    rules => [
        ### Root
        { lhs => 'json', rhs => [qw(some_data)] },

        ### Top level
        { lhs => 'some_data', rhs => [qw(array)] },
        { lhs => 'some_data', rhs => [qw(hash)] },
        { lhs => 'some_data', rhs => [qw(string)] },
        { lhs => 'some_data', rhs => [qw(null)] },

        ### Arrays
        { lhs => 'array', rhs => [qw(OPEN_BRACKET array_elements CLOSE_BRACKET)] },
        { lhs => 'array_elements', rhs => [qw(array_element COMMA array_elements)] },
        { lhs => 'array_elements', rhs => [qw(array_element)] },
        { lhs => 'array_element', rhs => [qw(some_data)] },

        ### Hashes
        { lhs => 'hash', rhs => [qw(OPEN_CURLY key_value_pairs CLOSE_CURLY)] },
        { lhs => 'key_value_pairs', rhs => [qw(key_value_pair COMMA key_value_pairs)] },
        { lhs => 'key_value_pairs', rhs => [qw(key_value_pair)] },
        { lhs => 'key_value_pair', rhs => [qw(STRING COLON some_data)] },

        ### Strings
        { lhs => 'string', rhs => [qw(STRING)] },

        ### Null
        { lhs => 'null', rhs => [qw(NULL)] },
    ],
});

$grammar->precompute;

my $rec = Marpa::XS::Recognizer->new( { grammar => $grammar } );
foreach my $token (@tokens) {
    if (defined $rec->read( @$token )) {
        $log->debug("reading Token: @$token");
    } else {
        $log->log_and_die("Error reading Token: @$token");
    };
}

my $output = ${$rec->value};
$log->notice(Data::Dumper->Dump([$output], ['final']));

sub do_default {
    $log->debug(Data::Dumper->Dump([ [@_] ],[ 'default' ]));
    return $_[1];
}

sub null {
    $log->debug(Data::Dumper->Dump([ [@_] ],[ 'null' ]));
    return undef;
}

sub hash {
    $log->debug(Data::Dumper->Dump([ [@_] ],[ 'hash' ]));
    return $_[2];
}

sub key_value_pairs {
    $log->debug(Data::Dumper->Dump([ [@_] ],[ 'key_value_pairs' ]));
    my %h;
    for (keys %{$_[1]}) {
        $h{$_} = $_[1]->{$_};
    }
    for (keys %{$_[3]}) {
        $h{$_} = $_[3]->{$_};
    }
    return \%h;
}

sub key_value_pair {
    $log->debug(Data::Dumper->Dump([ [@_] ],[ 'key_value_pair' ]));
    return {$_[1] => $_[3]};
}

sub array {
    $log->debug(Data::Dumper->Dump([ [@_] ],[ 'array' ]));
    return $_[2];
}

sub array_elements {
    $log->debug(Data::Dumper->Dump([ [@_] ],[ 'array_elements' ]));
    my @a = map {$_} $_[1], @{$_[3]};
    return \@a;
}

sub array_element {
    $log->debug(Data::Dumper->Dump([ [@_] ],[ 'array_element' ]));
    return $_[1];
}

sub some_data {
    $log->debug(Data::Dumper->Dump([ [@_] ],[ 'some_data' ]));
    return $_[1];
}

sub string {
    $log->debug("string:$_[1]");
    return $_[1];
}

sub json {
    $log->debug(Data::Dumper->Dump([ [@_] ],[ 'json' ]));
    return $_[1];
}
