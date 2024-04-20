#!perl
use 5.020;
use stable 'postderef';
use experimental 'signatures';
use Test2::V0 '-no_srand';
use Data::Dumper;

use URI::Template;
use URI::Template::Extract 'extract_parameters';
use YAML::PP 'Load';

# Our hacky data parser
my $tests = do { local($/); <DATA> };
my @tests = map {;
    my @pairs = /--- (\w+)\s+(.*?)\r?\n(?=---|\z)/msg
        or die "Bad line: $_";
    +{
        @pairs
    }
    } $tests =~ /(?:===\s+)(.*?)(?====|\z)/msg;

plan tests => 2 * @tests;

for my $block (@tests) {
    my $template  = $block->{template};
    my $url       = $block->{url};
    my $name_v    = $template;
    my $expected  = Load($block->{parameters});
    my $name      = $block->{name} // $name_v;

    my $todo;
    $todo = todo( $block->{todo})
        if $block->{todo};

    my $actual   = eval { extract_parameters( $template, $url ); };
    if( $@ ) {
        fail;
        SKIP: {
            skip($@, 1);
        }
    } else {
        is $actual, $expected, $name
            or diag Dumper [$actual,$expected];

        if( ! $actual ) {
            ok "Skipping, no reconstruction possible";

        } else {
            # Now, reconstruct the URL from our parsed thing:
            # URI template variables are not supposed to cross path boundaries,
            # so we fudge that manually afterwards
            my $t = URI::Template->new( $template );
            my $reconstructed = $t->process( $actual );
            $reconstructed .= $actual->{extra_path}
                if exists $actual->{extra_path};
            is $reconstructed, $url, "We can reconstruct the URL";
        };
    }
};

done_testing();

__DATA__
===
--- name
Identity gives empty parameters
--- url
https://example.com/
--- template
https://example.com/
--- parameters
{}
===
--- name
Extract path into extra_path
--- url
https://example.com/api/v1
--- template
https://example.com
--- parameters
extra_path: "/api/v1"
===
--- name
Extract server into variable
--- url
https://www1.example.com/
--- template
https://{host}.example.com/
--- parameters
host: "www1"
===
--- name
variable name with dashes
--- url
https://www1.example.com/
--- template
https://{host-name}.example.com/
--- parameters
host-name: "www1"
===
--- name
no match
--- url
https://www1.example.com/
--- template
https://{name}.test.example.com/
--- parameters
null
===
--- name
OpenAPI Server spec - port values
--- url
https://test.server.com:8443/v1/foo
--- template
https://{username}.server.com:{port}/{version}
--- parameters
port: 8443
version: v1
username: test
extra_path: "/foo"
