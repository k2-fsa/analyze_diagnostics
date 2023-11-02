#!/usr/bin/env python

import torch
import sys

# Usage:

# cd icefall/egs/librispeech/ASR/
# assuming you have previously trained a, say, zipformer model using:
#  python3 zipformer/train.py [args..]
# you could do, for instance, assuming this file's directory is on your PATH,
#  python3 compare_epochs.py zipformer/exp 4
# and it will compare zipformer/exp/epoch-4.pt and zipformer/exp/epoch-5.pt.

# and you have then dumped diagnostics with:
# python3 zipformer.py --print-diagnostics=True [args..] > some_file.txt
# then you


if __name__ == "__main__":
    argv = sys.argv
    assert len(argv) == 3
    model_dir = argv[1]
    epoch = int(argv[2])

    a = torch.load(f"{model_dir}/epoch-{epoch}.pt", map_location='cpu')
    try:
        b = torch.load(f"{model_dir}/epoch-{epoch+1}.pt", map_location='cpu')
    except:
        print(f"Model {model_dir}/epoch-{epoch+1}.pt does not exist, comparing previous one with itself")
        b = a

    try:
        f = open(f"{model_dir}/analyze_epoch{epoch}.txt", "w")
    except:
        f = open(f"/dev/null", "w")

    s = f"Output of: {argv[0]} {model_dir} {epoch}"
    print(s)
    print(s, file=f)


    def normalize(x):
        return x / ((x**2).mean().sqrt())


    try:
        a = a['model']
        b = b['model']
    except KeyError:
        pass

    for k in a.keys():
        v_old = a[k].clone()
        v_new = b[k].clone()
        if v_old.dtype == torch.float32:
            norm = ((v_old**2).sum()/v_old.numel()).sqrt()
            rel_diff = ((normalize(v_new)-normalize(v_old))**2).mean().sqrt()
            rel_diff = '%.2g' % rel_diff # (norm_diff / (norm+1e-20))
            norm = '%.2g' % norm
            if v_old.numel() == 1:
                s = f"For {k}, value={v_old.item():.2g}->{v_new.item():.2g}"
            else:
                s = f"For {k}, rms={norm}[diff={rel_diff}]"
            print(s)  # echo to stdout, plus save in file.
            print(s, file=f)


    #s2 = [ [ (k, m['model'][k].mean()) for k in [ x for x in m['model'].keys() if '_scale' in x ] ] for m in [a] ]
    #print(s2)  # echo to stdout, plus save in file.
    #print(s2, file=f)


# [ [ (k, m['model'][k].mean()) for k in [ x for x in m['model'].keys() if 'scale_' in x ] ] for m in [a] ]

# for branch in specaugmod_baseline_randcombine1_pelu{,_base,_dbefore}; do git checkout $branch; python3 ./transducer_stateless/train.py --world-size 1 --num-epochs 20 --start-epoch 3 --full-libri 0 --max-duration 300 --lr-factor 1.5 --print-diagnostics=True  >& stats/${branch}_epoch3.txt; done
