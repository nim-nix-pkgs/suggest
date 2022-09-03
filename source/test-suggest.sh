#!/bin/sh
if [ $# -lt 1 ]; then cat <<- EOF
Usage:

  [ md=1 qd=1 .. ] $0 <N1> [ <N2> <N3>... ]

This is a benchmarking harness for 'suggest' that takes as primary arguments
the size of the 'head's of a corpus file \$freq "word<spc>freq<newline>".

This data is used to 'suggest makeTypos' sampled from the actual frequency
distribution and then 'suggest compare' the SymSpell and linear scan algos,
reporting mean +- stddev(mean) milliseconds per word to get suggestions.
Additional environment variable controls are a the top of the script.

This script also supports timing the impact of Huge TLB Virtual Memory pages
using a Linux hugetlbfs mounted on /TMP with sufficient room for the data
files generated by \$freq and \$md.  I've measured 2-4x query speed-up @d<4
(larger than the SymSpell-vs-scan boost for md=4,qd=4 and 20000 word dicts).
To use HUGETLB=1, add '/etc/sysctl.conf:vm.nr_hugepages = 1024', and also
add '/etc/fstab:nodev /TMP hugetlbfs defaults,size=2048m 0 0', mkdir /TMP &
either reboot or 'echo 3 > /proc/sys/vm/drop_caches; sysctl -a; mount -a'.
Since hugetlbfs rounds file sizes to 2MB, we build in /tmp (an ordinary
tmpfs for me, but any FS will do) and 'suggest cpHuge' data files to /TMP
(GNU 'cp' fails for hugetlbfs) and use 'suggest -r' to let 'suggest' know
true file sizes.  \$HUGESAVE=1 also skips a final /TMP purge.
EOF
    exit
fi
: ${freqs:="/tmp/freqs"}
: ${d:=1}  # Number of deletes in makeTypos -d {1..4}
: ${b:=6}  # Batch size in makeTypos -s {1..6}
: ${md:=2} # MaxMaxDist update -d Distance {1..4}
: ${qd:=2} # Query dmax query -d Distance {1..4}
: ${qm:=5} # Matches query -m {1..10}

set -e
rm -rf /tmp/[0-9][0-9]*

meanPmSdev() {
  awk '{print sum += $1, n += 1, ssq += $1*$1}' |
    tail -n1 |
    awk '{print $1 / $2, "+-", (($3 / $2 - ($1 / $2)^2)/$2)^0.5 }'
}

for z in $*; do
  dir=/tmp/$z
  mkdir -p $dir/typos
  (cd $dir
    head -n $z $freqs > freqs
    suggest update -pp -d$md -i freqs &
    suggest makeTypos -d$d -s$b -p freqs -o typos/ -n2001 &
    wait
    if [ x$HUGETLB = x ]; then
        suggest compare -pp --dmax=$qd -m$qm -d typos > both
    else
        rm -f /TMP/p.corp /TMP/p.keys /TMP/p.meta /TMP/p.sugg /TMP/p.tabl
        for f in p.corp p.keys p.meta p.sugg p.tabl; do
            suggest cpHuge "$f" "/TMP/$f"   #GNU cp fails for hugetlbfs!
        done
        suggest compare -p/TMP/p -r p --dmax=$qd -m$qm -d typos > both
        if [ x$HUGESAVE = x ]; then
            rm -f /TMP/p.corp /TMP/p.keys /TMP/p.meta /TMP/p.sugg /TMP/p.tabl
        fi
    fi
    awk '{print $2}' < both > Via-scan
    awk '{print $4}' < both > Via-qry
    echo "sz $z  scan: " $(meanPmSdev < Via-scan)
    echo "sz $z  qry: "  $(meanPmSdev < Via-qry)
#    gnuplot <<-EOF
#	set term png small size 1080,1080
#	set output "cdfs.png"
#	set style data points
#	set title 'Vocab Size $z'
#	set xlab 'timeRank'
#	set ylab 'ms'
#	plot 'Via-scan' u 0:1, 'Via-qry' u 0:1
#EOF
  )
done
