package MJSON::Grammar;

use 5.14.0;

our $default = {
    start => 'json',
    actions => 'MJSON::ParseActions',
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

1;
