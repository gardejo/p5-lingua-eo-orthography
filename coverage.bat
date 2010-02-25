@REM for MS Windows (with Strawberry Perl)
@echo off

setlocal
set HARNESS_PERL_SWITCHES=-MDevel::Cover=+ignore,^inc/,^examples/,perl/site/lib/,perl/lib/,^t/,^xt/

rd /s /q cover_db 2>nul
REM dmake realclean

perl Makefile.PL
dmake manifest
dmake

prove -l && cover && start cover_db/coverage.html
