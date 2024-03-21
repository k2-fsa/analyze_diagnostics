#!/usr/bin/env perl


# cd icefall/egs/librispeech/ASR/
# assuming you have previously trained a, say, zipformer model using:
#  python3 zipformer/train.py [args..]
# and you have dumped diagnostics with:
# python3 zipformer/train.py --start-epoch=10 --print-diagnostics=True [args..] > zipformer/exp/diagnostics_epoch10.txt
#
# then you could do:
#
# param_importance.pl <zipformer/exp/diagnostics_epoch10.txt
# or:
# param_importance.pl <zipformer/exp/diagnostics_epoch10.txt | sort -gr -k2 | head


# other older examples follow; no guarantee of quality or applicability as modules names have
# changed.
# ~/bin/param_importance.pl pruned_transducer_stateless7/scaled_adam_exp204_1job_md600/diagnostics_epoch15.txt  | sort -gr -k2 | tail
#
# ~/bin/param_importance.pl <p*7/*381*/diag*15.txt | sort -k2 -gr | grep -E '^..(self_attn.|feed_forward.|attention_squeeze.|self_attn_weights|conv_module|nonlin_attention_module) \S+$' | head -n 10

# ~/bin/param_importance.pl <p*7/*386*/diag*15.txt | sort -k2 -gr | grep -E 'self_attn1|feed_forward.|attention_squeeze.|self_attn_weights|conv_module' | head -n 20
# takes as stdin a diagnostics file from icefall by running train.py with --print-diagnostics True.
# for conformers.

# this is for analyzing the relative importance of different parameters.

# Sub-module relative importance:
# ~/bin/param_importance.pl <p*7/*291*/diag*15.txt | sort -k2 -gr | grep -E '^..(self_attn.|feed_forward.|squeeze_excite.|self_attn|attention_squeeze.|self_attn_weights|conv_module) \S+$' | head -n 9
#
# Relative importance of stacks:
#  ~/bin/param_importance.pl <p*7/*291*/diag*15.txt | sort -k2 -gr | grep -E '^encoder.encoders..(|.encoder).layers '

# submodules of attention_squeeze
#  ~/bin/param_importance.pl pruned_transducer_stateless7/scaled_adam_exp389_1job_md600/diagnostics_epoch15.txt  | sort -gr -k2 | awk '{print NR, $0;}' | grep squeeze | grep -v layers | grep -v -E '^[0-9]+ ..[0-9]'

my %data;


my %modules;


my %seendim;

while (<>) {
  # Could make this rms instead of abs.  I was trying to get more "typical" values, to
  # ignore situations where the largest value actually has a small grad.
  if (m/^module=(.*).param_value, dim=0, size=\d+, abs .+mean=(.+),/) {
      $value_rms{$1} = $2;
    }
  if (m/^module=(.*).param_grad, dim=0, size=\d+, abs .+mean=(.+),/) {
    $grad_rms{$1} = $2;
  }

  if (m/^module=(.*).param_value, dim=(\d+), size=(\d+), abs .+mean=/) {
    if (!defined $seendim{$1,$2}) {
      $seendim{$1,$2} = 1;  # this is in case, for some reason, the same thing appears twice in the file.
      if (! defined $num_params{$1}) { $num_params{$1} = 1; }
      $num_params{$1} *= $3;
    }
  }
}

# get importance for each parameter.  later we'll aggregate over modules.
while (my ($k, $v) = each %value_rms) {
  $g = $grad_rms{$k};
  $num_params = $num_params{$k};
  if (! $g) { $g = 0.0; }
  $importance{$k} = $v * $g * $num_params;

}


$tot_importance = 0.0;
while (my ($k, $imp) = each %importance) {
  $tot_importance += $imp;
}

while (my ($k, $imp) = each %importance) {
  @a = split('\.', $k);  # e.g. if $k is "foo.bar", @a would be ("foo", "bar")
  $prefix = "";
  for ($i = 0; $i < @a; $i++) {
    if ($i == 0) { $prefix = $a[$i]; }
    else { $prefix = $prefix . "." . $a[$i]; }
    $key = $prefix;
    #if ($key != $k) {
    #  $k = $key . ".*";
    #}
    if (! defined $all_importance{$key}) {
      $all_importance{$key} = 0;
    }
    $all_importance{$key} += $imp;
  }
}
%importance = %all_importance;  # but keep %all_importance, do not zero it.

while (my ($k, $imp) = each %importance) {
  @a = split('\.', $k);  # e.g. if $k is "foo.bar", @a would be ("foo", "bar")
  for ($i = @a-1; $i > 0; $i--) {
    if ($i == @a-1) { $suffix = $a[@a-1]; }
    else { $suffix = $a[$i] . "." . $suffix; }
    $key = "*." . $suffix;
    if (! defined $all_importance{$key}) {
      $all_importance{$key} = 0;
    }
    $all_importance{$key} += $imp;
  }
}


foreach my $k (sort keys %all_importance) {
  $imp = $all_importance{$k};
  $imp = $imp / $tot_importance;  # Normalize.
  $imp = sprintf("%.4g", $imp);
  print("$k $imp\n");
}
