package MJSON;

use 5.14.0;

use Mouse;
use Method::Signatures;
use Marpa::XS;
use Log::Dispatch;
use Data::Dumper;

our $default_grammar_def = {
    start => 'json',
    actions => 'MJSON',
    default_action => 'do_default',
    terminals => [qw(
        OPEN_CURLY CLOSE_CURLY
        OPEN_BRACKET CLOSE_BRACKET
        COMMA COLON
        STRING NULL BOOL
    )],
    rules => [
        ### Root
        { lhs => 'json', rhs => [qw(some_data)] },

        ### Top level
        { lhs => 'some_data', rhs => [qw(array)] },
        { lhs => 'some_data', rhs => [qw(hash)] },
        { lhs => 'some_data', rhs => [qw(string)] },
        { lhs => 'some_data', rhs => [qw(bool)] },
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

        ### Boolean
        { lhs => 'bool', rhs => [qw(BOOL)] },

        ### Null
        { lhs => 'null', rhs => [qw(NULL)] },
    ],
};

has 'log' => (
    is => 'ro',
    isa => 'Log::Dispatch',
    default => sub {Log::Dispatch->new()},
);

has 'grammar' => (
    is => 'ro',
    isa => 'Marpa::XS::Grammar',
    default => sub {Marpa::XS::Grammar->new($MJSON::default_grammar_def)},
);

has 'recognizer' => (
    is => 'rw',
    isa => 'Marpa::XS::Recognizer',
);

func token_itr(Str $json) {
    my $line = 1;
    return sub {
      TOKEN: {
            $line++ if $json =~ /\G \n/gcx;
            return ['COMMA' => {line=>$line}]
                if $json =~ /\G , /gcx;

            return ['COLON' => {line=>$line}]
                if $json =~ /\G : /gcx;

            return ['OPEN_BRACKET' => {line=>$line}]
                if $json =~ /\G \[ /gcx;

            return ['CLOSE_BRACKET' => {line=>$line}]
                if $json =~ /\G \] /gcx;

            return ['OPEN_CURLY' => {line=>$line}]
                if $json =~ /\G { /gcx;

            return ['CLOSE_CURLY' => {line=>$line}]
                if $json =~ /\G } /gcx;

            return ['STRING' => {line=>$line, value=>$1}]
                if $json =~ /\G "([^"]*)"/gcx;

            return ['NULL' => {line=>$line}]
                if $json =~ /\G null /gcx;

            return ['BOOL' => {line=>$line, value=>$1}]
                if $json =~ /\G (true|false) /gcx;

            redo TOKEN
                if $json =~ /\G \s+ /gcx;

            return undef;
        }
    };
}

method tokenize(Str $json) {
    my $itr = token_itr($json);
    my @tokens;

    my $t;
    push @tokens, $t while ($t = $itr->());

    $self->log->debug(Data::Dumper->Dump([\@tokens], ['tokens']));

    return @tokens;
}

method BUILD(@args) {
    $self->grammar->precompute;
    $self->recognizer(
        Marpa::XS::Recognizer->new( {grammar => $self->grammar, trace_terminals => 2} )
    );
}

sub do_default {
    #$self->log->debug(Data::Dumper->Dump([ [@_] ],[ 'default' ]));
    return $_[1];
}

sub bool {
    #$self->log->debug(Data::Dumper->Dump([ [@_] ],[ 'bool' ]));
    return ($_[1]{value} eq 'false') ? undef : 1;
}

sub null {
    #$self->log->debug(Data::Dumper->Dump([ [@_] ],[ 'null' ]));
    return undef;
}

sub hash {
    #$self->log->debug(Data::Dumper->Dump([ [@_] ],[ 'hash' ]));
    return $_[2];
}

sub key_value_pairs {
    #$self->log->debug(Data::Dumper->Dump([ [@_] ],[ 'key_value_pairs' ]));
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
    #$self->log->debug(Data::Dumper->Dump([ [@_] ],[ 'key_value_pair' ]));
    return {$_[1]{value} => $_[3]};
}

sub array {
    #$self->log->debug(Data::Dumper->Dump([ [@_] ],[ 'array' ]));
    return $_[2];
}

sub array_elements {
    #$self->log->debug(Data::Dumper->Dump([ [@_] ],[ 'array_elements' ]));
    my @a = map {$_} $_[1], @{$_[3]};
    return \@a;
}

sub array_element {
    #$self->log->debug(Data::Dumper->Dump([ [@_] ],[ 'array_element' ]));
    return $_[1];
}

sub some_data {
    #$self->log->debug(Data::Dumper->Dump([ [@_] ],[ 'some_data' ]));
    return $_[1];
}

sub string {
    #$self->log->debug(Data::Dumper->Dump([ [@_] ],[ 'string' ]));
    return $_[1]{value};
}

sub json {
    say Dumper \@_;
    #$self->log->debug(Data::Dumper->Dump([ [@_] ],[ 'json' ]));
    return $_[1];
}

method parse(Str $json) {
    my @tokens = $self->tokenize($json);

    for my $token (@tokens) {
        if (defined $self->recognizer->read( @$token )) {
            $self->log->debug("Reading token: ".Data::Dumper->Dump($token, ['token']));
        }
        else {
            $self->log->log_and_die(level => 'fatal',
                              message => sprintf('Error near line %d reading token "%s".',
                                                 $token->[1]{line}, $token->[0]));
        }
    }

    my $output = ${$self->recognizer->value};
    $self->log->notice(Data::Dumper->Dump([$output], ['final']));
    return $output;
}

1;
