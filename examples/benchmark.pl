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
Intel Core2 6300 @1.86GHz, 1GB RAM):

 ----------------------------------------------------------------
 Benchmark: timing 50000 iterations of Orthography->new, Supersignoj->nova...
 Orthography->new:  3 wallclock secs ( 3.11 usr +  0.00 sys =  3.11 CPU) @ 16077.17/s (n=50000)
 Supersignoj->nova:  4 wallclock secs ( 4.70 usr +  0.00 sys =  4.70 CPU) @ 10633.77/s (n=50000)
                      Rate Supersignoj->nova  Orthography->new
 Supersignoj->nova 10634/s                --              -34%
 Orthography->new  16077/s               51%                --
 ----------------------------------------------------------------
 Benchmark: timing 50000 iterations of Orthography->convert, Supersignoj->transkodigu...
 Orthography->convert:  2 wallclock secs ( 1.94 usr +  0.00 sys =  1.94 CPU) @ 25813.11/s (n=50000)
 Supersignoj->transkodigu: 10 wallclock secs ( 9.72 usr +  0.00 sys =  9.72 CPU) @ 5144.56/s (n=50000)
                             Rate Supersignoj->transkodigu   Orthography->convert
 Supersignoj->transkodigu  5145/s                       --                   -80%
 Orthography->convert     25813/s                     402%                     --

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
