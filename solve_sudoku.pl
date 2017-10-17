#!/usr/bin/perl

use strict ;
use warnings ;
use utf8 ;
binmode STDOUT, ':utf8' ;
use feature qw{ postderef say signatures state } ;
no warnings qw{ experimental::postderef experimental::signatures } ;
use subs qw{ solve_sudoku test_solution display_puzzle no_go_list } ;

my @array ;
my @test ;
my $x = 0 ;
my $debug = 0 ;
my $outcount = 0 ;

#READ IN DATA
while ( my $line = <DATA> ) {
    chomp $line ;
    $line =~ s{\D}{ }mxg ;
    my @line = split m{|}mx , $line ;
    for my $y ( 0 .. 8 ) {
        if ( $line[$y] =~ m{\d}mx ) { $array[$x][$y] = $line[$y] ; }
        else {                        $array[$x][$y] = '' ; }
        }
    $x++ ;
    }

solve_sudoku( 0 , 0 , '' ) ;

#-------------------------------------------------------------------------------
sub solve_sudoku {
    my $x = shift ;
    my $y = shift ;
    exit if !defined $x ;
    exit if !defined $y ;
    my $nx ;
    my $ny ;
    my $history = shift ;
    my @tmp_array ;

    # MAKE TEMP ARRAY
    for my $a ( 0 .. 9 ) {
        for my $b ( 0 .. 9 ) {
            $tmp_array[$a][$b] = $array[$a][$b] ;
            }
        }

    # MAKE TEMP ARRAY
    for my $tmp ( split m{\s}mx , $history ) {
        if ( $tmp =~ /\d\d\d/ ) {
            my ( $xx , $yy , $vv ) ;
            $tmp =~ m{(\d)(\d)(\d)}mx ;
            $xx = $1 ; $yy = $2 ; $vv = $3 ;
            my $v = $tmp_array[$xx][$yy] =~ m{\d}mx ;
            if ( $tmp_array[$xx][$yy] =~ m{\d}mx ) {
                $debug and say '            FAIL EXISTS ' . $xx . $yy . $v ;
                return 0 ;
                }
            $tmp_array[$xx][$yy] = $vv ;
            }
        }
    return if ! test_solution( \@tmp_array ) ; #0 if fail

    my @no_go = no_go_list 0 , 0 , \@tmp_array ;

    # SHOW CURRENT STATE
    #say 'X: ' . $x ;
    #say 'Y: ' . $y ;
    #say 'No-go: ' . join ',' , @no_go ;
    #display_puzzle \@tmp_array ;

    my $current = $tmp_array[$x][$y] ;
    $nx = $x ;
    $ny = $y + 1 ;
    if ( $ny > 8 ) {
        $ny = 0 ;
        $nx = $x + 1 ;
        }
    exit if !defined $nx ;
    exit if !defined $ny ;
    if ( $current =~ m{\d}mx ) { # current position is filled
        solve_sudoku( $nx , $ny , $history ) ;
        }
    else { # current possition is empty ;
        for my $v ( 1 .. 9 ) {
            $tmp_array[$x][$y] = $v ;
#            next if grep m{$v} , @no_go ;
            solve_sudoku( $nx , $ny , $history . ' ' . $x . $y . $v ) ;
            }
        }
    }
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub test_solution {
    # If incomplete and wrong, return 0
    # If incomplete and right, return 1
    # If complete   and right, exit and display
    my $ptr_array = shift ; #pointer to a potentially solved puzzle

    {   # Horizontal
        for my $x (0 .. 8 ) {
            my %error ;
            for my $y ( 0 .. 8 ) {
                my $val = $$ptr_array[$x][$y] ;
                if ( defined $val ) {
                    next if $val =~ m{\D}mx ;
                    $error{ $val }++ ;
                    }
                }
            for my $e ( sort keys %error ) {
                if ( $error{$e} > 1 && $e =~ m{\d}mx ) {
                    $debug and say 'FAIL HORIZONTAL ' . $e ;
                    return 0 ;
                    }
                }
            }
        }

    {   # Vertical
        for my $y ( 0 .. 8 ) {
            my %error ;
            for my $x ( 0 .. 8 ) {
                my $val = $$ptr_array[$x][$y] ;
                if ( defined $val ) {
                    next if $val =~ m{\D}mx ;
                    $error{ $val }++ ;
                    }
                }
            for my $e ( sort keys %error ) {
                if ( $error{$e} > 1 && $e =~ m{\d}mx ) {
                    $debug and say 'FAIL VERTICAL ' . $e ;
                    return 0 ;
                    }
                }
            }
        }

    {   # blocks
        my @range ;
        $range[0][0] = 0 ;        $range[0][1] = 1 ;        $range[0][2] = 2 ;
        $range[1][0] = 3 ;        $range[1][1] = 4 ;        $range[1][2] = 5 ;
        $range[2][0] = 6 ;        $range[2][1] = 7 ;        $range[2][2] = 8 ;

        for my $a ( 0 ..2 ) {
            for my $b ( 0 ..2 ) {
                my @x = $range[$a] ;
                my @y = $range[$b] ;
                my %error ;
                for my $i ( 0 .. 2 ) {
                    for my $j ( 0 .. 2 ) {
                        my $x = $range[$a][$i] ;
                        my $y = $range[$b][$j] ;
                        my $val = $$ptr_array[$x][$y] ;
                        if ( defined $val ) {
                            next if $val =~ m{\D}mx ;
                            $error{ $val }++ ;
                            }
                        }
                    }
                for my $e ( sort keys %error ) {
                    if ( $error{$e} > 1 && $e =~ m{\d}mx ) {
                        $debug and say 'FAIL BLOCK ' . $e ;
                        return 0 ;
                        }
                    }
                }
            }
        }

    {   # ALL GOOD
        my $c = 0 ; #numberof numbers in array
        for my $y ( 0 .. 8 ) {
            for my $x ( 0 .. 8 ) {
                my $val = $$ptr_array[$x][$y] ;
                if ( defined $val && $val =~ m{\d}mx ) {
                    $c++ ;
                    }
                }
            }
        if ( $c == 81 ) {
            say 'GOOD' ;
            display_puzzle $ptr_array ;
            exit ;
            }
        }
    return 1 ;
    }
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub no_go_list {
    my $xx        = shift ; #current x position
    my $yy        = shift ; #current y position
    my $ptr_array = shift ; #pointer to a potentially solved puzzle
    my %error ;

    {   # Horizontal
        for my $x ( $xx .. $xx ) {
            for my $y ( 0 .. 8 ) {
                my $val = $$ptr_array[$x][$y] ;
                if ( defined $val ) {
                    next if $val =~ m{\D}mx ;
                    $error{ $val }++ ;
                    }
                }
            }
        }

    {   # Vertical
        for my $y ( $yy .. $yy ) {
            my %error ;
            for my $x ( 0 .. 8 ) {
                my $val = $$ptr_array[$x][$y] ;
                if ( defined $val ) {
                    next if $val =~ m{\D}mx ;
                    $error{ $val }++ ;
                    }
                }
            }
        }

    return grep m{\d} , sort keys %error ;

    {   # blocks
        my @range ;
        $range[0][0] = 0 ;        $range[0][1] = 1 ;        $range[0][2] = 2 ;
        $range[1][0] = 3 ;        $range[1][1] = 4 ;        $range[1][2] = 5 ;
        $range[2][0] = 6 ;        $range[2][1] = 7 ;        $range[2][2] = 8 ;

        for my $a ( 0 ..2 ) {
            for my $b ( 0 ..2 ) {
                my @x = $range[$a] ;
                my @y = $range[$b] ;
                my %error ;
                for my $i ( 0 .. 2 ) {
                    for my $j ( 0 .. 2 ) {
                        my $x = $range[$a][$i] ;
                        my $y = $range[$b][$j] ;
                        my $val = $$ptr_array[$x][$y] ;
                        if ( defined $val ) {
                            next if $val =~ m{\D}mx ;
                            $error{ $val }++ ;
                            }
                        }
                    }
                }
            }
        }
    return grep m{\d} , sort keys %error ;
    }
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
sub display_puzzle {
    my $ptr_array = shift ; #pointer to a potentially solved puzzle
    say '        -------------' ;
    for my $x ( 0 .. 8 ) {
        print '        ' ;
        for my $y ( 0 .. 8 ) {
            my $v = $$ptr_array[$x][$y] ;
            if ( $v !~ m{\d}mx ) { $v = '_' ; }
            print $v  ;
            print '  ' if $y == 2 ;
            print '  ' if $y == 5 ;
            }
        say '' ;
        say '' if $x == 2 ;
        say '' if $x == 5 ;
        }
    say '        -------------  ' ;
    say '' ;
    }
#-------------------------------------------------------------------------------


##-------------------------------------------------------------------------------
#sub solve_sudoku_junk {
#    my $test = shift ;
#    my @tmp_array ;
#
#    for my $a ( 0 .. 9 ) {
#        for my $b ( 0 .. 9 ) {
#            $tmp_array[$a][$b] = $array[$a][$b] ;
#            }
#        }
#
#    # MAKE TEMP ARRAY
#    for my $tmp ( split m{\s}mx , $test ) {
#        if ( $tmp =~ /\d\d\d/ ) {
#            my ( $xx , $yy , $vv ) ;
#            $tmp =~ m{(\d)(\d)(\d)}mx ;
#            $xx = $1 ; $yy = $2 ; $vv = $3 ;
#            my $v = $tmp_array[$xx][$yy] =~ m{\d}mx ;
#            if ( $tmp_array[$xx][$yy] =~ m{\d}mx ) {
#                $debug and say '            FAIL EXISTS ' . $xx . $yy . $v ;
#                return 0 ;
#                }
#            $tmp_array[$xx][$yy] = $vv ;
#            }
#        }
#
#    $debug and say 'TESTING: ' . $test ;
#    my @scal = split m{\s}mx , $test ;
#    my $scal = scalar @scal ;
#    my $test_sol = test_solution( \@tmp_array ) ;
#    $outcount++ ;
#    if ( $outcount % 10000 == 0 ) {
#        display_puzzle \@tmp_array if $outcount % 1000 == 0 ;
#        say join '#' , $scal , $test_sol , $outcount ;
#        }
#    if ( $test_sol == 0 ) {##fail
#        $debug and say 'FAIL' ;
#        return ;
#        }
#    for my $x ( 0 .. 8 ) {
#        for my $y ( 0 .. 8 ) {
#            if ( $tmp_array[$x][$y] !~ m{\d}mx ) {
#                for my $v ( 1 .. 9 ) {
#                    my $new_test = join '' , $test , ' ' , $x , $y , $v  ;
#                    next if $tmp_array[$x][$y] =~ m{\d}mx ;
#                    $debug and say '    NEW TEST: ' . $new_test ;
#                    solve_sudoku $new_test ;
#                    }
#                }
#            }
#        }
#
#    return 0 ;
#    }
##-------------------------------------------------------------------------------

exit 0 ;
#===============================================================================

#__DATA__
#1_8_9____
#2__3_8_96
#_0____4__
#4_6__9_3_
#_1_2_5_6_
#_8_6__2_1
#__1____4_
#36_9_4__7
#____6_3_5

# 94_1_7__8
# _____35__
# _6_48__1_
# 5__87_3__
# _7_____6_
# __8_49__7
# _5__34_8_
# __75_____
# 3__7_8_95
__DATA__
17_____42
_3_____5_
____9____
__39621__
_________
__21375__
3_14_98_7
6___8___3
4_______5