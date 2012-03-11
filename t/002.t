#!/usr/bin/env perl

use 5.14.0;

use MJSON;
use Test::More;

my @tests = (
    {json => q/
[
"q",
"w",
{"A" : "B", "C" : "D"},
"e
",
false,
true,
"r"
]
/,
     expected => [
         "q",
         "w",
         {"A" => "B", "C" => "D"},
         "e
",
         undef,
         1,
         "r"
     ]
 },
    {
        json => q/{
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
/,
        expected => {
            "glossary" => {
                "title" => "example glossary",
                "GlossDiv" => {
                    "title" => "S",
                    "GlossList" => {
                        "GlossEntry" => {
                            "ID" => "SGML",
                            "SortAs" => "SGML",
                            "GlossTerm" => "Standard Generalized Markup Language",
                            "Acronym" => "SGML",
                            "Abbrev" => "ISO 8879:1986",
                            "GlossDef" => {
                                "para" => "A meta-markup language, used to create markup languages such as DocBook.",
                                "GlossSeeAlso" => ["GML", "XML"]
                            },
                            "GlossSee" => "markup"
                        }
                    }
                }
            }
        }
    },
    {
        json => q/
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
/,
        expected =>
{"menu" => {
    "header" => "SVG Viewer",
    "items" => [
        {"id" => "Open"},
        {"id" => "OpenNew", "label" => "Open New"},
        undef,
        {"id" => "ZoomIn", "label" => "Zoom In"},
        {"id" => "ZoomOut", "label" => "Zoom Out"},
        {"id" => "OriginalView", "label" => "Original View"},
        undef,
        {"id" => "Quality"},
        {"id" => "Pause"},
        {"id" => "Mute"},
        undef,
        {"id" => "Find", "label" => "Find..."},
        {"id" => "FindAgain", "label" => "Find Again"},
        {"id" => "Copy"},
        {"id" => "CopyAgain", "label" => "Copy Again"},
        {"id" => "CopySVG", "label" => "Copy SVG"},
        {"id" => "ViewSVG", "label" => "View SVG"},
        {"id" => "ViewSource", "label" => "View Source"},
        {"id" => "SaveAs", "label" => "Save As"},
        undef,
        {"id" => "Help"},
        {"id" => "About", "label" => "About Adobe CVG Viewer..."}
    ]
}}
    },
    {
        json => q/"A\"B"/,
        expected => 'A"B'
    },
);


for my $test (@tests) {
    my $output = MJSON->new->parse($test->{json});
    is_deeply($output, $test->{expected});
}

done_testing;

__DATA__
