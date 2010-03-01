package Lingua::EO::Orthography;


# ****************************************************************
# perl dependency
# ****************************************************************

use 5.008_001;


# ****************************************************************
# pragma(s)
# ****************************************************************

use strict;
use warnings;
use utf8;


# ****************************************************************
# general depencency(-ies)
# ****************************************************************

use Carp qw(confess);
use Data::Util qw(:check neat);
use List::MoreUtils qw(any apply uniq);
use Memoize qw(memoize);
use Regexp::Assemble;
use Try::Tiny;


# ****************************************************************
# version
# ****************************************************************

our $VERSION = "0.00";


# ****************************************************************
# constructor
# ****************************************************************

sub new {
    my ($class, %init_arg) = @_;

    my $self = bless {}, $class;

    $self->sources(
          exists $init_arg{sources} ? $init_arg{sources}
        :                             ':all'
    );
    $self->target(
          exists $init_arg{target}  ? $init_arg{target}
        :                             'orthography'
    );

    return $self;
}


# ****************************************************************
# accessor(s) for attribute(s)
# ****************************************************************

sub sources {
    my ($self, $source_notation_candidates_ref) = @_;

    if (scalar @_ > 1) {    # $self->sources(undef) comes here and dies
        if (
            defined $source_notation_candidates_ref &&
            $source_notation_candidates_ref eq ':all'
        ) {
            $self->{sources} = [
                grep {
                    $_ ne 'orthography';
                } keys %{ $self->_notation }
            ];
        }
        else {
            try {
                $self->_check_source_notations($source_notation_candidates_ref);
            }
            catch {
                confess "Could not set source notations because: " . $_;
            };
            $self->{sources} = [ uniq @$source_notation_candidates_ref ];
        }
    }

    return $self->{sources};
}

sub target {
    my ($self, $target_notation_candidate) = @_;

    if (scalar @_ > 1) {    # $self->target(undef) comes here and dies
        try {
            $self->_check_notations($target_notation_candidate);
        }
        catch {
            confess "Could not set a target notation because: " . $_;
        };
        $self->{target} = $target_notation_candidate;
    }

    return $self->{target};
}


# ****************************************************************
# utility(-ies) for attribute(s)
# ****************************************************************

sub all_sources {
    my $self = shift;

    return @{ $self->{sources} };
}

sub add_sources {
    my ($self, @adding_notations) = @_;

    try {
        $self->_check_notations(@adding_notations);
    }
    catch {
        confess "Could not add source notations because: " . $_;
    };
    @{ $self->{sources} } = uniq $self->all_sources, @adding_notations;

    return $self->{sources};
}

sub remove_sources {
    my ($self, @removing_notations) = @_;

    try {
        $self->_check_notations(@removing_notations);
        die 'Converter must maintain at least one source notation'
            if (scalar $self->all_sources) == (scalar uniq @removing_notations);
    }
    catch {
        confess "Could not remove source notations because: " . $_;
    };

    # Note: I dare do not use List::Compare to get complement notations
    my %removing_notation;
    @removing_notation{ @removing_notations } = ();
    $self->{sources} = [
        grep {
            ! exists $removing_notation{$_};
        } $self->all_sources
    ];

    return $self->{sources};
}


# ****************************************************************
# converter(s)
# ****************************************************************

sub convert {
    my ($self, $string) = @_;

    confess sprintf 'Could not convert string because '
                  . 'string (%s) must be a primitive value',
                neat($string)
        unless is_value($string);

    my $source_pattern   = $self->_source_pattern( @{ $self->sources } );
    my $target_character = $self->_target_character( $self->target );

    $string =~ s{
        ($source_pattern)
    }{$target_character->{$1}}xmsg;

    return $string;
}


# ****************************************************************
# checker(s)
# ****************************************************************

sub _check_notations {
    my ($self, @notation_candidates) = @_;

    my $notation_ref = $self->_notation;

    map {
        die sprintf 'Notation (%s) must be a primitive value',
                    neat($_)
            unless is_value($_);

        die sprintf 'Notation (%s) does not enumerated',
                    neat($_)
            unless exists $notation_ref->{$_};
    } @notation_candidates;

    return;
}

sub _check_source_notations {
    my ($self, $source_notation_candidates_ref) = @_;

    confess 'Source notations must be an array reference'
        unless is_array_ref($source_notation_candidates_ref);
    confess 'Source notations must be a nonnull array reference'
        unless @$source_notation_candidates_ref;

    $self->_check_notations(@$source_notation_candidates_ref);

    return;
}


# ****************************************************************
# internal properties
# ****************************************************************

sub _notation {
    return {
        orthography => [(           # LATIN [CAPITAL|SMALL] LETTER ...
            "\x{108}", "\x{109}",   #   ... C WITH CIRCUMFLEX
            "\x{11C}", "\x{11D}",   #   ... G WITH CIRCUMFLEX
            "\x{124}", "\x{125}",   #   ... H WITH CIRCUMFLEX
            "\x{134}", "\x{135}",   #   ... J WITH CIRCUMFLEX
            "\x{15C}", "\x{15D}",   #   ... S WITH CIRCUMFLEX
            "\x{16C}", "\x{16D}",   #   ... U WITH BREVE
        )],
        zamenhof            => [qw(Ch ch Gh gh Hh hh Jh jh Sh sh U  u )],
        capital_zamenhof    => [qw(CH ch GH gh HH hh JH jh SH sh U  u )],
        postfix_h           => [qw(Ch ch Gh gh Hh hh Jh jh Sh sh Uw uw)],
        postfix_capital_h   => [qw(CH ch GH gh HH hh JH jh SH sh UW uw)],
        postfix_x           => [qw(Cx cx Gx gx Hx hx Jx jx Sx sx Ux ux)],
        postfix_capital_x   => [qw(CX cx GX gx HX hx JX jx SX sx UX ux)],
        postfix_caret       => [qw(C^ c^ G^ g^ H^ h^ J^ j^ S^ s^ U^ u^)],
        postfix_apostrophe  => [qw(C' c' G' g' H' h' J' j' S' s' U' u')],
        prefix_caret        => [qw(^C ^c ^G ^g ^H ^h ^J ^j ^S ^s ^U ^u)],
    };
}

sub _source_pattern {
    my ($self, @source_notations) = @_;

    my $regexp_assembler = Regexp::Assemble->new;
    my $notation_ref     = $self->_notation;

    SOURCE_NOTATION:
    foreach my $source_notation (@source_notations) {
        SOURCE_CHARACTER:
        foreach my $source_character (
            @{ $notation_ref->{ $source_notation } }
        ) {
            next SOURCE_CHARACTER
                if $source_character =~ m{ \A [Uu] \z }xms;
            ( my $escaped_source_character = $source_character )
                =~ s{ (?=\^) }{\\}xms;
            $regexp_assembler->add($escaped_source_character);
        }
    }

    return $regexp_assembler->re;
}

sub _target_character {
    my ($self, $target_notation) = @_;

    return ( $self->_converter_table )->{$target_notation};
}

# Returns table as {$target_notation}{'source_character'} => 'target_character'
sub _converter_table {
    my $self = shift;

    my $converter_table;
    my $source_notations_ref = $self->_notation;
    my $target_notation_ref  = { %$source_notations_ref };

    TARGET_NOTATION:
    while (
        my ($target_notation, $target_characters_ref)
            = each %$target_notation_ref
    ) {
        SOURCE_NOTATION:
        while (
            my ($source_notation, $source_characters_ref)
                = each %$source_notations_ref
        ) {
            next SOURCE_NOTATION
                if $source_notation eq $target_notation;

            SOURCE_CHARACTER:
            foreach my $index ( 0 .. $#{$source_characters_ref} ) {
                next SOURCE_CHARACTER
                    if $source_characters_ref->[$index]
                        =~ m{ \A [Uu] \z }xms;
                $converter_table->{ $target_notation }
                                  { $source_characters_ref->[$index] }
                    = $target_characters_ref->[$index];
            }
        }
    }

    return $converter_table;
}


# ****************************************************************
# memoization
# ****************************************************************

sub _memoize_methods {
    map {
        memoize $_
    } qw(
        _check_notations
        _check_source_notations
        _notation
        _source_pattern
        _target_character
        _converter_table
    );

    return;
}


# ****************************************************************
# compile-time process(es)
# ****************************************************************

__PACKAGE__->_memoize_methods;


# ****************************************************************
# return true
# ****************************************************************

1;
__END__


# ****************************************************************
# POD
# ****************************************************************

=encoding utf8

=pod

=head1 NAME

Lingua::EO::Orthography - A converter of notations (orthography and transliterations) for Esperanto characters

=head1 VERSION

This document describes C<Lingua::EO::Orthography> version C<0.00>.

=head2 Translations

=over 4

=item en: English

L<Lingua::EO::Orthography|Lingua::EO::Orthography> (This document)

=item eo: Esperanto

L<Lingua::EO::Orthography::EO|Lingua::EO::Orthography::EO>

=item ja: Japanese

L<Lingua::EO::Orthography::JA|Lingua::EO::Orthography::JA>

=back

=head1 SYNOPSIS

    use utf8;
    use Lingua::EO::Orthography;

    my ($converter, $source, $target);

    # Orthographize ...
    $converter = Lingua::EO::Orthography->new;
        # Same as above:
        # $converter = Lingua::EO::Orthography->new(
        #     sources => ':all',
        #     target  => 'orthography',
        # );
    $source = q(C^i-momente, la songha h'orajxo )
            . q(^sprucigas aplauwdon.);         # Source: transliteration
    $target = $converter->convert($source);     # Target: UTF-8 orthography
    # The sentence means "In this moment, the dreamy chorus spurts applause."

    # Substitute ... (X-system)
    $converter->sources([qw(orthography)]);     # (accepts plural notations)
    $converter->target('postfix_x');
        # Same as above:
        # $converter = Lingua::EO::Orthography->new(
        #     sources => [qw(orthography)],
        #     target  => 'postfix_x',
        # );
    $source = "\x{108}i-momente, la son\x{11D}a \x{125}ora\x{135}o "
            . "\x{153}prucigas apla\x{16D}don"; # Source: UTF-8 orthography
    $target = $converter->convert($source);     # Target: X-system

=head1 DESCRIPTION

blah blah blah

=head2 Caveat

B<This module is in stage of beta release, and API may be changed.
Your feedback is welcome.>

=head2 Catalogue of Notations

blah blah blah

=head2 Comparison with Lingua::EO::Supersignoj

 Viewpoints                 ::Supersignoj   ::Orthography               Note
 -------------------------- --------------- --------------------------- ----
 Version                    0.02            0.00
 Can convert @lines         Yes             No                          *1
 Have accessors             Yes             Yes, and it has utilities   *2
 Can customize notation     Only 'u'        No (under consideration)    *3
 Can treat 'flughaveno'     No              No (under consideration)    *4
 API language               eo: Esperanto   en: English
 Can do N:1 conversion      No              Yes                         *5
 Speed                      Satisfied       About 400% faster           *6
 Immediate dependencies     3? (2? in core) 9? (4? in core)             *7
 Whole dependencies         3? (2? in core) 22? (12? in core)           *7
 Test case numbers          3               75
 License                    Unknown         Perl (Artistic or GNU GPL)
 Last modified on           Mar. 2003       Mar. 2010

=over 4

=item 1.

To convert C<@lines> with L<Lingua::EO::Orthography|Lingua::EO::Orthography>:

    @converted_lines = map { $converter->convert($_) } @original_lines;

=item 2.

L<Lingua::EO::Orthography|Lingua::EO::Orthography> has utility methods,
what are L<all_sources()|/all_sources>, L<add_sources()|/add_sources> and
L<remove_sources()|/remove_sources()>.

=item 3.

I plan to design the API of this function:

    $converter = Lingua::EO::Orthography->new(
        notations => {
            postfix_asterisk => [qw(C* c* G* g* H* h* J* j* S* s* U* u*)],
        },
    );

    $notations_ref = $converter->notations;

    @notations = $converter->all_notations;

    @notations = $converter->notations({
        postfix_underscore => [qw(C_ c_ G_ g_ H_ h_ J_ j_ S_ s_ U_ u_)],
    });

    $converter->add_notations(
        postfix_diacritics => [qw(C^ c^ G^ g^ H^ h^ J^ j^ S^ s^ U~ u~)],
    );

=item 4.

I plan to design the API of this function:

    $converter = Lingua::EO::Orthography->new(
        ignore_words => [qw(
            bushaltejo flughaveno Kinghaio ...
        )],
    );

    $ignore_words_ref = $converter->ignore_words;

    @ignore_words = $converter->all_ignore_words;

    @ignore_words = $converter->ignore_words([qw(kuracherbo)]);

    $converter->add_ignore_words([qw(
        longhara navighalto ...
    )]);

=item 5.

I expect that you may design your practical application
to accept plural notations, from my experience.

=item 6.

L<Lingua::EO::Orthography|Lingua::EO::Orthography> can convert strings
about 400% faster than L<Lingua::EO::Supersignoj|Lingua::EO::Supersignoj>.

The reason for the difference is to cache a pattern of regular expression
and a character converting table to replace string, with L<Memoize|Memoize>.
Furthermore, L<Lingua::EO::Orthography|Lingua::EO::Orthography> can
convert characters from plural notations at once.

See F</examples/benchmark.pl> in this distribution.

=item 7.

The source of dependencies is L<http://deps.cpantesters.org/>.

Such number excludes modules for building and testing.

Any dependencies of L<Lingua::EO::Orthography|Lingua::EO::Orthography> have
a certain favorable opinion. I quite agree with those recommendation.

But, I consider reducing dependencies.
I already abandon make this module to depend
L<namespace::clean|namespace::clean>,
L<namespace::autoclean|namespace::autoclean>, and so on.

=back

=head1 METHODS

=head2 Constructor

=head3 C<< new >>

    $object = Lingua::EO::Orthography->new(%init_arg);

blah blah blah

=head2 Converter

=head3 C<< convert >>

    $converted_string = $object->convert($original_string);

blah blah blah

=head2 Accessors

=head3 C<< sources >>

    $source_notations_ref = $object->sources;

blah blah blah

    $source_notations_ref = $object->sources(\@notations);

blah blah blah

=head3 C<< target >>

    $target_notation = $object->target;

blah blah blah

    $target_notation = $object->target($notation);

blah blah blah

=head2 Utilities

=head3 C<< all_sources >>

    @all_source_notations = $object->all_sources;

blah blah blah

=head3 C<< add_sources >>

    $source_notations_ref = $object->add_sources(@adding_notations);

blah blah blah

=head3 C<< remove_sources >>

    $source_notations_ref = $object->remove_sources(@removing_notations);

=head1 SEE ALSO

=over 4

=item *

L. L. Zamenhof, I<Fundamento de Esperanto>, 1905

=item *

L<http://en.wikipedia.org/wiki/Esperanto_orthography>

=item *

L<Lingua::EO::Supersignoj|Lingua::EO::Supersignoj>

=item *

L<http://freshmeat.net/projects/eoconv/>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 TO DO

=over 4

=item *

More tests

=item *

To correctly convert C<flughaveno> (C<flug/haven/o>) in C<postfix_h> notation
with user's lexicon

=item *

Don't to convert characters in string what formatted by URI (RFC 2396, 3986)
and by mail address (RFC 5321, 5322)

=item *

To release a L<Moose|Moose> friendly class
C<Lingua::EO::Orthography::Moosified> as an other distribution

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head2 Making suggestions and reporting bugs

Please report any found bugs, feature requests, and ideas for improvements
to C<bug-lingua-eo-orthography at rt.cpan.org>,
or through the web interface
at L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Lingua-EO-Orthography>.
I will be notified, and then you'll automatically be notified of progress
on your bugs/requests as I make changes.

When reporting bugs, if possible,
please add as small a sample as you can make of the code
that produces the bug.
And of course, suggestions and patches are welcome.

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

    % perldoc Lingua::EO::Orthography

The Esperanto edition of documentation is available.

    % perldoc Lingua::EO::Orthography::EO

You can also find the Japanese edition of documentation for this module
with the C<perldocjp> command from L<Pod::PerldocJp|Pod::PerldocJp>.

    % perldocjp Lingua::EO::Orthography::JA

You can also look for information at:

=over 4

=item RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Lingua-EO-Orthography>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-EO-Orthography>

=item Search CPAN

L<http://search.cpan.org/dist/Lingua-EO-Orthography>

=item CPAN Ratings

L<http://cpanratings.perl.org/dist/Lingua-EO-Orthography>

=back

=head1 VERSION CONTROL

This module is maintained using I<git>.
You can get the latest version from
L<git://github.com/gardejo/p5-lingua-eo-orthography.git>.

=head1 CODE COVERAGE

I use L<Devel::Cover|Devel::Cover> to test the code coverage of my tests,
below is the C<Devel::Cover> summary report on this distribution's test suite.

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt   bran   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 .../Lingua/EO/Orthography.pm  100.0  100.0  100.0  100.0  100.0  100.0  100.0
 Total                         100.0  100.0  100.0  100.0  100.0  100.0  100.0
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

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
