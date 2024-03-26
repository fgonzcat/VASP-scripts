#!/bin/bash

dir=$PWD
for f in "$@"
do
 d=$dir/$f
 echo -n -e "\n\033[34m==>\e[0m\033[1m Analyzing\033[31m  $d \e[0m\n"

 # Collect all OUTCARs
 ff=""
 for i in {1..100}
 do
    if [ -e $d/out$i/OUTCAR ]; then
      ff=`echo $ff $d/out$i/OUTCAR`
    fi
 done
 if [ -e $d/OUTCAR ]; then
     ff=`echo $ff $d/OUTCAR`
 fi

 tein=$(grep -h -m 1 'TEIN' $d/OUTCAR| awk '{print $3}')
 tebeg=$(grep -h -m 1 "TEBEG" $d/INCAR| awk '{print $3}')
 kB=0.000086173303372172   # in eV/K
 N=$(grep -h "NIONS =" $d/OUTCAR -m 1 | awk '{print $NF}')
 
 #echo "$tein" "$tebeg" | awk '{if($1*1 != $2*1) {print '$tebeg'} else print "'$tein'" }' > $d/temp.dat
# grep -h "kinetic Energy EKIN" $ff |awk '{print $(NF-1)}'|sed -e 's/(temperature//g' > $d/temp.dat # Version 4.x, 5.x
# grep -h "EKIN_LAT" $ff |awk '{print $(NF-1)}'|sed -e 's/(temperature//g' >> $d/temp.dat             # Version 5.4
 
 echo "Calculating EKIN"
 grep -h "EKIN " $ff | awk '{print $5}'                                > $d/Kin.dat
 
 # Any version: at high T, Fortran runs out of characters for T, but not for EKIN
 cat $d/Kin.dat | awk -v N=$N '{printf("%.3f\n" ,11604.506*2*$1/(3*N-3))}' > $d/temp.dat #  <K>=3/2 NkT => T = K/(1.5 N k),  eV/kboltzmann =  11604.506 K       

 echo "Calculating Pressure"
 grep -h "external pressure" $ff | awk '{print $4/10}' > $d/press.dat
 grep -h "total pressure" $ff | awk '{print $4/10}' > $d/totpress.dat

 echo "Calculating Volume"
# grep -h "volume " $ff | awk '{print $NF}' > $d/vol.dat #| sed -e '$d' > $d/vol.dat
 V=$(grep -h volume $ff -m 2|tail -1|awk '{print $NF}')

 echo "Calculating TOTEN (free energy F)"
 grep -h "ion-electron   TOTEN" $ff | awk '{print $(NF-2)}'             > $d/F.dat # Same as "free  energy   TOTEN"

 echo "Calculating ETOTAL= TOTEN+EKIN+ES+EPS (energy Etot)"
 grep -h "total energy   ETOTAL" $ff | awk '{print $(NF-1)}'            > $d/Etot.dat

 echo "Calculating Energy Without Entropy (Pot)"
 grep -h "y  w" $ff | awk '{printf("%.10f\n",$4)}'                        > $d/Pot.dat   # energy  without entropy 

 echo "Calculating Total Energy ETOTAL (Kin+F)"                        # Not very realistic, since it includes the smearing, which is non physical.
 grep -h "ETOTAL" $ff | awk '{print $5}'                                > $d/etotal.dat   # This is the one that remains constant in NVE (microcanonical)


 # CANONICAL ENSEMBLE 
 if [ "`awk '{ if ( match($0,/SMASS/)!=0 && $3==0 && substr($0,1,1)!="#") print "NVT" }' $d/INCAR`" == "NVT" ]; then
  echo "Calculating TOTAL ENERGY (Kin+Pot) in NVT ensemble"
  #awk -v N=$N -v T=$tebeg -v kB=$kB '{print $1/N + 1.5*N*kB*T/N }'     $d/Pot.dat > $d/E.dat   # Assuming equipartition <K>=3/2 N*kb*T (canonical)
  awk -v N=$N -v T=$tebeg -v kB=$kB '{print $1   + 1.5*N*kB*T   }'     $d/Pot.dat > $d/E.dat   # Assuming equipartition <K>=3/2 N*kb*T (canonical)
  echo "Correcting Pressure (using thermostat T)..."
  awk -v N=$N -v T=$tebeg -v V=$V -v kB=$kB '{toGPa=160.217662079999996649; print $1+N*kB*T/V*toGPa}' $d/press.dat > $d/newpress.dat             # Thermostat temperature
 
 # MICROCANONICAL ENSEMBLE 
 else
 echo "Calculating TOTAL ENERGY (Kin+Pot) in NVE ensemble"
  paste $d/Kin.dat $d/Pot.dat | awk '{print $1+$2}'                      > $d/E.dat  # Instantaneous EKin+E_without_entropy
 echo "Correcting Pressure using instantaneous temperature..."
  paste $d/press.dat $d/temp.dat | awk -v N=$N -v kB=$kB -v V=$V '{print $1+N*kB*$2/V}' > $d/newpress.dat   # Instantaneous temperature
 fi



# paste temp.dat vol.dat > $d/TV.dat
# METHOD 1

#METHOD 2
# awk '{print '$kB'*'$N'*$1/$2}' temp.dat | head -n -1 > $d/diff.dat  # Instantaneous temperature
# awk '{print '$kB'*'$N'*'$tebeg'/$2}' TV.dat | head -n -1 > $d/diff.dat  # Thermostat mean temperature
# paste press.dat diff.dat | awk '{print $1+$2}' > $d/newpress.dat
# rm TV.dat diff.dat
 #cd ..
 
 echo "Adding Time column..."
 dt=$(grep -h -m 1 'POTIM' $d/OUTCAR | awk '{print $3}')
 files="$(echo `find $d/ -maxdepth 1  -iname '*.dat' -mmin -1`)"
 for dat in $files
 do
  awk -v dt=$dt '{print dt*(NR-1),$1}' $dat | column -t > tmp.tmp
  mv tmp.tmp $dat
 done
 
 


done
