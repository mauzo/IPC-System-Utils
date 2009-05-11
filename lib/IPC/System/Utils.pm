package IPC::System::Utils;

use warnings;
use strict;

our $VERSION = 0.01;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/quote_arg quote_cmd system_err system_redir/;

use File::Spec;

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

1;
