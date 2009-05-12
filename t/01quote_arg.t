#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use Config;

use IPC::System::Utils qw/quote_arg/;

my $echo;

BEGIN {
    ECHO: {
        # Win32 echo doesn't strip quotes. I am assuming
        # double-quotes are valid on all platforms.
        for ($Config{echo}, qq/$^X -le"print \@ARGV" --/) {

            $echo = $_;

            qx/$echo foo/ eq "foo\n" 
                and qx/$echo "foo"/ eq "foo\n"
                and last ECHO;
        }

        plan skip_all => "echo doesn't work";
        exit 0;
    }
}

my $t;

diag "Using '$echo' as echo";

sub is_q {
    my ($str, $name) = @_;
    my $B = Test::More->builder;

    my $quote = quote_arg $str;
    diag $quote;
    my $got = qx/$echo $quote/;
    $B->is_eq($got, "$str\n", $name);
}

BEGIN { $t += 12 }

is_q "foo",             "plain string";
is_q "foo bar",         "spaces";
is_q "Foo",             "uppercase";
is_q "foo'bar",         "single quote";
is_q "''foo' bar",      "multiple single-quotes";
is_q qq/foo"bar/,       "double quote";
is_q "foo^bar",         "caret";
is_q "foo\$bar",        "dollar";
is_q "foo;bar",         "semicolon";
is_q "foo<bar>",        "angles";
is_q "# foo",           "hash";
is_q "foo\tbar",        "tab";

BEGIN { plan tests => $t }
