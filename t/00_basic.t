use strict;
use warnings;
use utf8;

use Test::More tests => 3;

# Note: This test imported from Lingua::EO::Supersignoj

BEGIN {
    use_ok('Lingua::EO::Orthography');
};

my $converter = Lingua::EO::Orthography->new(
    sources => [qw(postfix_x)],
);
can_ok(
    $converter,
    qw(
        convert
    ),
);

my $output;
foreach my $notation (qw(
    orthography
    postfix_x
    postfix_capital_x
    zamenhof
    capital_zamenhof
    postfix_h
    postfix_capital_h
    postfix_caret
    prefix_caret
    postfix_apostrophe
)) {
    $converter->target($notation);
    $output .= $converter->convert(
        'Laux Ludoviko Zamenhof bongustas ' .
        'fresxa cxecxa mangxajxo kun spicoj.'
    );
}

# To do: subdivide tests
ok(
    $output eq join '', (
        "La\x{16d} Ludoviko Zamenhof bongustas fre\x{15d}a \x{109}e\x{109}a man\x{11d}a\x{135}o kun spicoj.",
        "Laux Ludoviko Zamenhof bongustas fresxa cxecxa mangxajxo kun spicoj.",
        "Laux Ludoviko Zamenhof bongustas fresxa cxecxa mangxajxo kun spicoj.",
        "Lau Ludoviko Zamenhof bongustas fresha checha manghajho kun spicoj.",
        "Lau Ludoviko Zamenhof bongustas fresha checha manghajho kun spicoj.",
        "Lauw Ludoviko Zamenhof bongustas fresha checha manghajho kun spicoj.",
        "Lauw Ludoviko Zamenhof bongustas fresha checha manghajho kun spicoj.",
        "Lau^ Ludoviko Zamenhof bongustas fres^a c^ec^a mang^aj^o kun spicoj.",
        "La^u Ludoviko Zamenhof bongustas fre^sa ^ce^ca man^ga^jo kun spicoj.",
        "Lau' Ludoviko Zamenhof bongustas fres'a c'ec'a mang'aj'o kun spicoj.",
    )
);

# To do: write TODO tests, and so on.
# flughaveno

# To do: More tests
