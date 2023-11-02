#!/usr/bin/env perl

$x = "";
while (<>) {
  if (m/finite/ && $x !~ m/finite/){ print; }
  $x = $_;
}
