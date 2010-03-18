use inc::Module::Install 0.95;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

# ================================================================
# gathering meta information
# ================================================================
    # abstract, author, license, name, perl_version(5.008_001), version
    all_from        'lib/Lingua/EO/Orthography.pm';

    # supplements
    author          'MORIYA Masaki, alias Gardejo <moriya at cpan dot org>';
    resources (
        repository
            => 'git://github.com/gardejo/p5-lingua-eo-orthography.git',
        # (implicit assignment)
        # bugtracker
        #     => 'http://rt.cpan.org/Public/Dist/Display.html?Name='
        #      . 'Lingua-EO-Orthography',
        homepage
            => 'http://github.com/gardejo/p5-lingua-eo-orthography',
    );

    no_index directory => 'examples';
#   no_index directory => 'extlib';

# ================================================================
# build dependency(-ies)
# ================================================================
#   build_requires  'Module::Install'                   => '0.80';
        # to avoid YAML::Tiny problem
#   build_requires  'Module::Load'                      => '0';
        # is in perl 5.009_004

# ================================================================
# general dependency(-ies)
# ================================================================
#   requires        'Carp'                              => '0';
        # was included by perl 5
    requires        'Data::Util'                        => '0';
    requires        'List::MoreUtils'                   => '0';
#   requires        'Memoize'                           => '0';
        # was included by perl 5.007_003
    requires        'Regexp::Assemble'                  => '0';
    requires        'Try::Tiny'                         => '0';

# ================================================================
# test dependency(-ies)
# ================================================================
    test_requires   'Test::Class'                       => '0.34';
        # to avoid Devel::Symdump
    test_requires   'Test::Exception'                   => '0.27';
        # cf. MooseX-Types-DateTime
    test_requires   'Test::More'                        => '0';
    test_requires   'Test::Requires'                    => '0';
    test_requires   'Test::Warn'                        => '0';

# ================================================================
# author dependency(-ies)
# ================================================================
    author_requires 'Perl::Critic'                      => '0.094';
    author_requires 'Test::CPAN::Meta'                  => '0.12';
#   author_requires 'Test::Kwalitee'                    => '0';
        # always die (but xt/kwalitee.t need it)
    author_requires 'Test::NoTabs'                      => '0';
    author_requires 'Test::Perl::Critic'                => '0';
    author_requires 'Test::Pod'                         => '1.40';
    author_requires 'Test::Pod::Coverage'               => '1.08';
    author_requires 'Test::Synopsis'                    => '0.06';
    author_requires 'Test::UseAllModules'               => '0';

# ================================================================
# test(s)
# ================================================================
    tests                   't/*.t';
    recursive_author_tests  'xt';

# ================================================================
# including
# ================================================================
    auto_include_deps;
    # 'auto_include' grabs only immediate dependencies

# ================================================================
# installation
# ================================================================
#   auto_install;
    # 'auto_install' is deprecated

# ================================================================
# writter
# ================================================================
    WriteAll;
