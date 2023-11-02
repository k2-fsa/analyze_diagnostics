#!/usr/bin/env perl



# takes as stdin the output of compare_epochs.py



while (<>) {
  if (m/For (.+), rms=.+\[diff=(.+)\]$/) {
    $k = $1;
    $d = $2 + 0;
    @a = split('\.', $k);  # e.g. if $k is "foo.bar", @a would be ("foo", "bar")
    $prefix = "";
    for ($i = 0; $i < @a; $i++) {
      if ($i == 0) { $prefix = $a[$i]; }
      else { $prefix = $prefix . "." . $a[$i]; }
      $key = $prefix;

      #      if ($key != $k) {
      #  $key = $key . ".*";
      #}

      if (! defined $all_diff{$key}) {
        $all_diff{$key} = 0;
        $all_count{$key} = 0;
      }
      $all_diff{$key} += $d;
      $all_count{$key} += 1;
    }
  }
}


%diff = %all_diff;  # but keep %all_diff, do not zero it.

while (my ($k, $d) = each %diff) {
  @a = split('\.', $k);  # e.g. if $k is "foo.bar", @a would be ("foo", "bar")
  $n = $all_count{$k};
  for ($i = @a-1; $i > 0; $i--) {
    if ($i == @a-1) { $suffix = $a[@a-1]; }
    else { $suffix = $a[$i] . "." . $suffix; }
    $key = "*." . $suffix;
    if (! defined $all_diff{$key}) {
      $all_diff{$key} = 0;
      defined $all_count{$key} && die;
      $all_count{$key} = 0;
    }
    $all_diff{$key} += $d;
    $all_count{$key} += $n;
  }
}



foreach my $k (sort keys %all_diff) {
  $d = $all_diff{$k};
  $n = $all_count{$k};
  $imp = sprintf("%.4g", $d / $n);
  print("$k $imp\n");
}
