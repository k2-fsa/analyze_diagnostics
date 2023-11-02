#!/usr/bin/env perl


# takes as stdin a diagnostics file from icefall by running train.py with --print-diagnostics True.
# This is for a version of icefall that has special code in diagnostics.py for Balancer and
# AbsValuePenalizer that print out their parameters.  It tells you how badly the various
# constraints are violated.


# this is for analyzing the relative contribution of different modules in conformer layers.

# e.g.:
# ~/bin/show_violations.pl   zipformer1/zlm51/diagnostics_32000.out  | sort -n

my %data;


my %modules;
my %submodule_names;

while (<>) {
  if (! m/\.\./ && m/output, type=.*Balancer\[(\S+),(\S+),(\S+),(\S+)/) {
    # the string '..' will be present in the line if there are dims with variable size;
    # we don't want these.
    ($min_positive, $max_positive, $min_abs, $max_abs) = ($1, $2, $3, $4);

    if (m/, abs .*\[(.+)\]/) {
      @percentiles = split(" ", $1);
      $num_below_min_abs = 0;
      $num_above_max_abs = 0;
      foreach $p (@percentiles) {
        if ($p < $min_abs) { $num_below_min_abs++; }
        if ($p > $max_abs) { $num_above_max_abs++; }
      }
      $np = $#percentiles + 1;
      if ($num_below_min_abs > 0) {
        print("$num_below_min_abs/$np below min_abs=$min_abs: $_");
      }
      if ($num_above_max_abs > 0) {
        print("$num_above_max_abs/$np above max_abs=$max_abs: $_");
      }
    }
    if (m/, positive .*\[(.+)\]/) {
      @percentiles = split(" ", $1);
      $num_below_min_positive = 0;
      $num_above_max_positive = 0;
      foreach $p (@percentiles) {
        if ($p < $min_positive) { $num_below_min_positive++; }
        if ($p > $max_positive) { $num_above_max_positive++; }
      }
      $np = $#percentiles + 1;
      if ($num_below_min_positive > 0) {
        print("$num_below_min_positive/$np below min_positive=$min_positive: $_");
      }
      if ($num_above_max_positive > 0) {
        print("$num_above_max_positive/$np above max_positive=$max_positive: $_");
      }
    }
  }

  if (! m/\.\./ && m/output, type=AbsValuePenalizer\[(\S+)\]/) {
    $limit = $1;
    if (m/, (min|max) .*\[(.+)\]/) {
      $num_outside_limit = 0;
      @percentiles = split(" ", $2);
      foreach $p (@percentiles) {
        if (abs($p) > $limit) { $num_outside_limit++; }
      }
      $np = $#percentiles + 1;
      if ($num_outside_limit > 0) {
        print("$num_outside_limit/$np outside limit=$limit: $_");
      }
    }
  }
}
