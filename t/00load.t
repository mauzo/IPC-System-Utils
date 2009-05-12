#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 1;

use_ok("IPC::System::Utils");

grep !$_, Test::More->builder->summary
    and BAIL_OUT("module will not load");
