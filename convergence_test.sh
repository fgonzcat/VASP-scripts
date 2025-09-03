#!/usr/bin/env bash

#------------------------------------------------------------------------------------------------|
#  CONVERGENCE TEST FOR EVOLUTION OF BLOCKER AVERAGE                                             |
#                                                                                                |
# This code analyzes the output of ~/scripts/blocker_average                                     |
# It assumes you have the running average F_ev.dat, tot_press_ev.dat or similar in the folders.  |
# The output is the Convergence_Quality                                                          |
#                                                                                                |
# Felipe Gonzalez                                                          Berkeley, 08/27/2025  |
#------------------------------------------------------------------------------------------------|


files="$@"  # all arguments at execution time
for file in $files
do
 echo "f(n)= xinf + A*exp(-sqrt(n/tau)); xinf=-1000;A=-10;tau=300; fit [1000:][] f(x) '$file' u 2:4 via xinf,A,tau;  set print 'fit.log'; print sprintf('%.15g %.8g  %.8g', xinf, A, tau)" | gnuplot >& /dev/null
 read xinf A tau  <<<  `awk '{print $1,$2,$3}' fit.log `; rm fit.log
 awk -v xinf=$xinf -v A=$A -v tau=$tau -v name=$file 'END {xn=$4;xnE=$5; epsilon=10;fx=sprintf("f(x)= %.3f + %.3f*exp(-sqrt(x/%.3f))", xinf, A, tau);  printf("%-12s   %-55s  Convergence_Quality=  %6.2f %", name, fx, 100 * ( exp( -sqrt((xn-xinf)^2) / (epsilon*xnE) )) )  }' $file
 awk -v xinf=$xinf 'NR>1{n=$2; xn=$4;xnE=$5; d=sqrt((xn-xinf)^2); if (d<xnE) {good++; if (good==5){ M=n; exit} } else good=0;  }END{if (M*1>1) printf "  Converged_after_step_n= %i\n",M; else printf "  # NOT YET CONVERGED (may need more steps)\n"}' $file
done
