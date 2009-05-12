package IPC::System::Utils;

use warnings;
use strict;

our $VERSION = 0.01;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/quote_arg quote_cmd redir_std/;

use File::Spec;
use File::Temp  qw/tempfile/;
use Fcntl       qw/SEEK_SET/;

# taken from MakeMaker
sub _is_win95 {
    return defined &Win32::IsWin95
        ? Win32::IsWin95()
        : ! defined $ENV{SYSTEMROOT};
}

BEGIN {
    if ($^O eq "VMS") {
        *quote_arg = sub {
            my $x = @_ ? $_[0] : $_;
            $x =~ s{"}{""}g;
            return qq{"$x"};
        };
    }
    # OS/2 uses Unix syntax
    # MacOS is no longer supported
    # NetWare uses Win32 syntax
    # Win95 and WinNT syntax are the same
    elsif ($^O eq "MSWin32") {
        *quote_arg = sub {
            my $x = @_ ? $_[0] : $_;
            $x =~ s{"}{\\"}g;
            # Skip the dmake stuff. This isn't for Makefiles.
            return qq{"$x"};
        };
    }
    # UWIN uses Unix syntax
    # Cygwin uses Unix syntax
    # BeOS (Haiku) uses Unix syntax
    # DOS uses Unix systax (!) (this is DJGPP with bash)
    # VOS uses Unix syntax
    # QNX uses Unix syntax
    # AIX uses Unix syntax
    # Darwin uses Unix syntax
    else {
        *quote_arg = sub {
            my $x = @_ ? $_[0] : $_;
            $x =~ s{'}{'\\''}g;
            return qq{'$x'};
        };
    }
}

sub quote_cmd {
    my (@cmd) = @_;

    ref $cmd[0] or File::Spec->file_name_is_absolute($cmd[0])
        or $cmd[0] = File::Spec->rel2abs($cmd[0]);

    return
        join " ",
        map { ref() ? $$_ : quote_arg }
        @cmd;
}

sub redir_std (&@) {
    my ($cb, $stdin) = @_;

    my @STD = (\*STDIN, \*STDOUT, \*STDERR);
    my (@OLD, @NEW);

    $NEW[$_] = tempfile for 1..2;

    if (defined $stdin) {
        $NEW[0] = tempfile;
        print { $NEW[0] } $stdin;
        seek $NEW[0], 0, SEEK_SET;
    }
    else {
        open $NEW[0], "<", File::Spec->devnull
            or die "can't open null device: $!\n";
    }

    for (0..2) {
        my $dir = $_ ? ">" : "<";
        open $OLD[$_], "$dir&", $STD[$_];
        open $STD[$_], "$dir&", $NEW[$_];
    }

    my (@warn, $die, $rv);
    {
        local $SIG{__WARN__} = sub { push @warn, $_[0] };

        eval { $cb->() };
        $die = $@;
    }

    for (0..2) {
        my $dir = $_ ? ">" : "<";
        open $STD[$_], "$dir&", $OLD[$_];
    }

    warn $_ for @warn;
    $die and die "$die\n";

    my ($stdout, $stderr) = map {
        seek $NEW[$_], 0, SEEK_SET;
        local $/ = undef;
        readline $NEW[$_];
    } 1..2;

    return wantarray ? ($stdout, $stderr) : $rv;
}

1;
