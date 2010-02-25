#!perl

use strict;
use warnings;

use Benchmark qw(cmpthese timethese);

use Lingua::EO::Orthography;
use Lingua::EO::Supersignoj;

my $count = $ARGV[0] || 50_000;
my ($orthography, $supersignoj, $input);

print '-' x 64, "\n";
cmpthese(
    timethese(
        $count => {
            'Orthography->new' => sub {
                $orthography = Lingua::EO::Orthography->new(
                    sources => [qw(prefix_caret)],
                    target  => 'orthography',
                );
            },
            'Supersignoj->nova' => sub {
                $supersignoj = Lingua::EO::Supersignoj->nova(
                    de => 'fronte',
                    al => 'unikodo',
                );
            },
        }
    )
);

$input = 'Mia ^suoj estas anka^u en la ^cambro.';

print '-' x 64, "\n";
cmpthese(
    timethese(
        $count => {
            'Orthography->convert' => sub {
                $orthography->convert($input);
            },
            'Supersignoj->transkodigu' => sub {
                $supersignoj->transkodigu($input);
            },
        }
    )
);

__END__

=pod

=head1 NAME

benchmark.pl - Compare Lingua::EO::Orthography with Lingua::EO::Supersignoj

=head1 DESCRIPTION

L<Lingua::EO::Orthography|Lingua::EO::Orthography> has simplar implementation
than L<Lingua::EO::Supersignoj|Lingua::EO::Supersignoj>.

Therefore, C<Lingua::EO::Orthography> can convert string about 400% faster
than C<Lingua::EO::Supersignoj>.

=head1 EXAMPLE

In my environment (Strawberry Perl 5.10.0.1 on Windows XP Professional with SP3,
AMD Opteron 252 @ 2.6GHz * 2, 2GB RAM):

 ----------------------------------------------------------------
 Benchmark: timing 50000 iterations of Orthography->new, Supersignoj->nova...
 Orthography->new:  3 wallclock secs ( 2.89 usr +  0.00 sys =  2.89 CPU) @ 17301.04/s (n=50000)
 Supersignoj->nova:  4 wallclock secs ( 3.77 usr +  0.00 sys =  3.77 CPU) @ 13276.69/s (n=50000)
                      Rate Supersignoj->nova  Orthography->new
 Supersignoj->nova 13277/s                --              -23%
 Orthography->new  17301/s               30%                --
 ----------------------------------------------------------------
 Benchmark: timing 50000 iterations of Orthography->convert, Supersignoj->transkodigu...
 Orthography->convert:  2 wallclock secs ( 1.64 usr +  0.00 sys =  1.64 CPU) @ 30469.23/s (n=50000)
 Supersignoj->transkodigu:  9 wallclock secs ( 8.97 usr +  0.00 sys =  8.97 CPU) @ 5574.76/s (n=50000)
                             Rate Supersignoj->transkodigu   Orthography->convert
 Supersignoj->transkodigu  5575/s                       --                   -82%
 Orthography->convert     30469/s                     447%                     --

=head1 AUTHOR

=over 4

=item MORIYA Masaki (a.k.a. Gardejo)

C<< <moriya at cpan dot org> >>,
L<http://ttt.ermitejo.com/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 by MORIYA Masaki (a.k.a. Gardejo),
L<http://ttt.ermitejo.com/>.

This library is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
See L<perlgpl|perlgpl> and L<perlartistic|perlartistic>.

The full text of the license can be found in the F<LICENSE> file
included with this distribution.

=cut
