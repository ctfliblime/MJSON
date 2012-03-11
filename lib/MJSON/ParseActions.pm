package MJSON::ParseActions;

use 5.14.0;

use Method::Signatures;
use Data::Dumper;

func ddump($log, $data, $label) {
    $log->log(level => 'debug', message => sub {
                  Data::Dumper->Dump([ $data ],[ $label ]);
              });
}

func do_default($ppt, $data) {
    ddump($ppt->{log}, $data, 'DEFAULT');
    return $data;
}

func bool($ppt, $bool) {
    ddump($ppt->{log}, $bool, 'bool');
    return ($bool->{value} eq 'false') ? undef : 1;
}

func null($ppt, $null) {
    ddump($ppt->{log}, $null, 'null');
    return undef;
}

func hash($ppt, $null1, HashRef $hash, $null2) {
    ddump($ppt->{log}, $hash, 'hash');
    return $hash;
}

func key_value_pairs($ppt, @args) {
    ddump($ppt->{log}, \@_, 'key_value_pair');
    my %h;
    for (keys %{$_[1]}) {
        $h{$_} = $_[1]->{$_};
    }
    for (keys %{$_[3]}) {
        $h{$_} = $_[3]->{$_};
    }
    return \%h;
}

func key_value_pair($ppt, $key, $null, $value) {
    ddump($ppt->{log}, \@_, 'key_value_pair');
    return {$key->{value} => $value};
}

func array($ppt, $null0, $array, $null1) {
    ddump($ppt->{log}, $array, 'array');
    return $array;
}

func array_elements($ppt, @args) {
    ddump($ppt->{log}, \@_, 'array_elements');
    [ map {$_} $_[1], @{$_[3]} ];
}

func array_element($ppt, $elem) {
    ddump($ppt->{log}, $elem, 'array_element');
    return $elem;
}

func some_data($ppt, $data) {
    ddump($ppt->{log}, $data, 'some_data');
    return $data;
}

func string($ppt, $string) {
    ddump($ppt->{log}, $string, 'string');
    return $string->{value};
}

func json($ppt, $json) {
    ddump($ppt->{log}, $json, 'json');
    return $json;
}

1;
