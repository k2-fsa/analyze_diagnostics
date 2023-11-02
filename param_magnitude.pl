#!/usr/bin/env perl

# example of use:
# ~/bin/param_importance.pl pruned_transducer_stateless7/scaled_adam_exp204_1job_md600/diagnostics_epoch15.txt  | sort -gr -k2 | head
# ~/bin/param_importance.pl pruned_transducer_stateless7/scaled_adam_exp204_1job_md600/diagnostics_epoch15.txt  | sort -gr -k2 | tail
#
# ~/bin/param_importance.pl <p*7/*381*/diag*15.txt | sort -k2 -gr | grep -E '^..(self_attn.|feed_forward.|attention_squeeze.|self_attn_weights|conv_module|nonlin_attention_module) \S+$' | head -n 10

# p~/bin/param_importance.pl <p*7/*386*/diag*15.txt | sort -k2 -gr | grep -E 'self_attn1|feed_forward.|attention_squeeze.|self_attn_weights|conv_module' | head -n 20
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



while (<>) {
  # Could make this rms instead of abs.  I was trying to get more "typical" values, to
  # ignore situations where the largest value actually has a small grad.
  if (m/^module=(.*).param_value, dim=0, size=\d+, abs .+mean=(.+),/) {
    print("$1 $2\n");
  }
}
