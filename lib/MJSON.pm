package MJSON;

use 5.14.0;

our $VERSION = '0.000';

use Any::Moose;
use Method::Signatures;
use Marpa::XS;
use Log::Dispatch;
use Data::Dumper;
use MJSON::Grammar;
use MJSON::ParseActions;

has 'grammar' => (
    is => 'ro',
    isa => 'Marpa::XS::Grammar',
    default =>
        sub {Marpa::XS::Grammar->new($MJSON::Grammar::default)},
);

has 'recognizer' => (
    is => 'rw',
    isa => 'Marpa::XS::Recognizer',
);

has 'log' => (
    is => 'ro',
    isa => 'Log::Dispatch',
    default => sub {Log::Dispatch->new()},
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
    {
        no warnings qw(redefine);
        *MJSON::Logger::new = sub { return {log=>$self->log} };
    }
    $self->grammar->set({action_object => 'MJSON::Logger'});

    $self->grammar->precompute;
    $self->recognizer(
        Marpa::XS::Recognizer->new(
            {grammar => $self->grammar, trace_terminals => 0} )
    );
}

method parse(Str $json) {
    my @tokens = $self->tokenize($json);

    for my $token (@tokens) {
        if (defined $self->recognizer->read( @$token )) {
            $self->log->debug('TOKEN:'.$token->[0]);
        }
        else {
            $self->log->log_and_die(
                level => 'fatal',
                message => sprintf('Error near line %d reading token "%s".',
                                   $token->[1]{line}, $token->[0]));
        }
    }

    my $output = ${$self->recognizer->value};
    $self->log->debug(Dumper($output), 'final');
    return $output;
}

1;
