#!/bin/bash


if [ -z $1 ] ; then
 echo "Obtain the Temperature, Pressure, and Energies as a function of time from MD simulations [Berkeley 05-21-18]"
 echo ""
 echo "It creates the table with average energy, pressure, temperature, density, etc." 
 echo ""
 echo "Usage: $0  T-*"
 echo "Usage: $0  T-{25,30,53}00"
 echo "Usage: $0  Fe206"
 echo ""
 echo "SUMMARY OF THE FILES GENERATED"
 echo "================================"
 echo "Kin.dat                    ---> EKIN"
 echo "press.dat                  ---> 'external pressure' (just external, no ideal gas correction)"
 echo "totpress.dat               ---> external + ideal gas correction (instant. T)"
 echo "  press_KS.dat             ---> In machine learning, 'external pressure' (just Kohn-Sham, DFT pressures)"
 echo "  totpress_KS.dat          ---> In machine learning, external + ideal gas correction with instant. T (just Kohn-Sham, DFT pressures)"
 echo "F.dat                      ---> TOTEN= F = U_el - TS_el = Pot + EENTRO   [EENTRO = -TS])."
 echo "                                In machine learning, 'free  energy ML TOTEN' and TOTEN=Pot because F= ion-electron TOTEN = ML energy  without entropy = Pot.dat"
 echo "  F_KS.dat                 ---> In machine learning, 'free  energy   TOTEN' (just Kohn-Sham, DFT TOTEN)"
 echo "F_ion-electron.dat         ---> The 'see above ion-electron   TOTEN'  =  'free  energy   TOTEN') (In ML, contains both KS and ML TOTEN combined)"
 echo "Etotal.dat                 ---> ETOTAL= TOTEN+EKIN+ES+EPS (energy Etotal, includes thermostat)] "
 echo "Pot.dat                    ---> 'energy  without entropy'"
 echo "                                 In machine learning, 'ML energy  without entropy' and Pot.dat = F.dat = TOTEN' [so, it DOES contain entropy... misnomer]"
 echo "  Pot_KS.dat               ---> In machine learning, 'energy  without entropy' (just Kohn-Sham, DFT energies)"
 echo "E.dat                      ---> <E> = 3/2 NkT + 'energy  without entropy' = Actual thermodynamic total energy"
 echo "  E_KS.dat                 ---> In machine learning, Pot_KS + 3/2 NkT"
 exit
fi



dir=$PWD
PerAtom=1     # 1: True, 0: False


for f in "$@"
do
 d=$dir/$f
 echo -n -e "\n\033[34m==>\e[0m\033[1m Analyzing\033[31m  $d \e[0m\n"

 # Collect all OUTCARs
 ff=""
 for i in {1..999}
 do
    if [ -e $d/out$i/OUTCAR ]; then
      ff=`echo $ff $d/out$i/OUTCAR`
    fi
 done
 if [ -e $d/OUTCAR ]; then
     ff=`echo $ff $d/OUTCAR`
 fi

 if [ "$ff" == "" ]; then continue; fi
 tein=$(grep -h -m 1 'TEIN' $d/OUTCAR| awk '{print $3}')
 tebeg=$(grep -h -m 1 "TEBEG" $d/INCAR| awk '{print $3}')
 kB=0.000086173303372172   # in eV/K
 N=$(grep -h "NIONS =" $d/OUTCAR -m 1 | awk '{print $NF}')
 if [ "$PerAtom" == 1 ]; then
  NN=$N
  echo "Reporting properties per atom. N= " $NN
 else
  NN=1
 fi

 dt=$(grep -h -m 1 'POTIM' $d/OUTCAR| awk '{print $3}')
 NBLOCK=$(awk '/NBLOCK/{print $3}' $d/INCAR)
 #dt=`echo $dt $NBLOCK | awk '{print $1*$2}'`

 echo "Calculating EKIN                                      ---> $d/Kin.dat"
 grep -h "EKIN " $ff | awk '{print $5}'                                > $d/Kin.dat 
 # Any version: at high T, Fortran runs out of characters for T, but not for EKIN
 cat $d/Kin.dat      | awk -v N=$N  -v dt=$dt '{EKIN=$1; printf("%.1f  %.2f\n" ,NR*dt, 11604.506*2*EKIN/(3*N-3))}' > $d/temp.dat #  <K>=3/2 NkT => T = K/(1.5 N k),  eV/kboltzmann =  11604.506 K       
 grep -h "EKIN " $ff | awk -v N=$NN -v dt=$dt '{print NR*dt,$5/N}'                     > $d/Kin.dat   # <--- E/atom


 echo "Calculating Pressure                                  ---> $d/press.dat    (just external)"
 echo "Calculating Pressure                                  ---> $d/totpress.dat (external + ideal gas correction (instant. T))"
 if [ "$(grep 'ML_' $d/INCAR)" == "" ]; then
  grep -h "external pressure" $ff | awk -v dt=$dt '{print NR*dt,$4/10}' > $d/press.dat
  grep -h "total pressure" $ff    | awk -v dt=$dt '{print NR*dt,$4/10}' > $d/totpress.dat
 else 
 #==============  MACHINE LEARNING PRESSURES ===============#
  echo "    Machine Learning calculation                       ---> press.dat, totpress.dat, press_KS.dat, totpress_KS.dat"
  if [ "$(grep "TOTAL-FORCE" $d/OUTCAR  | grep -v ML)" == "" ]; then echo "" > $d/press_KS.dat;  echo "" > $d/totpress_KS.dat;
  else
  grep  -h 'POTIM\|Ionic step\|external pressure\|TOTAL-FORCE'  $ff  | awk ' /POTIM = /{dt=$3; N+=nstep} /Ionic step/{nstep=$4} /external pressure/{P=$4} /TOTAL-FORCE/ && !/ML/{ print (nstep+N-1)*dt,P/10 } '  > $d/press_KS.dat
  grep  -h 'POTIM\|Ionic step\|total pressure\|TOTAL-FORCE'     $ff  | awk ' /POTIM = /{dt=$3; N+=nstep} /Ionic step/{nstep=$4} /total pressure/   {P=$4}/TOTAL-FORCE/{if ($0 ~ "ML") P_ML=P; else {P_DFT=P; printf("%.2f  %8.4f  %8.4f\n", (nstep+N-1)*dt,P/10, P_ML/10)} } '  > $d/totpress_KS.dat
  fi
  grep  -h 'POTIM\|Ionic step\|external pressure\|TOTAL-FORCE'  $ff  | awk ' /POTIM = /{dt=$3; N+=nstep} /Ionic step/{nstep=$4} /external pressure/{P=$4} /TOTAL-FORCE/ && /ML/{ print (nstep+N-1)*dt,P/10 }'  >  $d/press.dat
  grep  -h 'POTIM\|Ionic step\|total pressure\|TOTAL-FORCE'     $ff  | awk ' /POTIM = /{dt=$3; N+=nstep} /Ionic step/{nstep=$4} /total pressure/{P=$4} /TOTAL-FORCE/ && /ML/{    print (nstep+N-1)*dt,P/10 }'  >  $d/totpress.dat
 fi
 #==========================================================#

 echo "Calculating Volume (to calculate NkT/V)"
 #grep -h "volume of cel" $ff | awk '{print $NF}' > $d/vol.dat #| sed -e '$d' > $d/vol.dat  # This only works for NVT
 grep -h 'POTIM\|Ionic step\| direct lattice vectors' $ff -A 3| awk ' /POTIM = /{dt=$3; N+=nstep} /Ionic step/{nstep=$4} /direct/{getline; a1=$1;a2=$2;a3=$3;getline;b1=$1;b2=$2;b3=$3;getline;c1=$1;c2=$2;c3=$3;     V= (a2*b3-a3*b2)*c1 - (a1*b3-a3*b1)*c2 + (a1*b2-a2*b1)*c3; printf("%.1f  %10.4f\n", (nstep+N)*dt,V)}'  > $d/vol.dat # NPT
 #V=$(grep -h volume $ff -m 2|tail -1|awk '{print $(NF-1)}')
 V=`awk 'BEGIN{getline;getline;f=$1;getline;ax=$1;ay=$2;az=$3;getline;bx=$1;by=$2;bz=$3;getline;cx=$1;cy=$2;cz=$3;V=ax*(by*cz-bz*cy)+ay*(bz*cx-bx*cz)+az*(bx*cy-by*cx);V*=f*f*f;printf("%.8f",V)}' $d/POSCAR`

 echo "Calculating free energy (F= TOTEN)                    ---> $d/F.dat (TOTEN= F = U_el - TS_el = Pot + EENTRO   [EENTRO = -TS]). In ML, TOTEN=F= ion-electron TOTEN = ML energy  without entropy = Pot_ML"
 echo "Calculating free energy (F= ion-electron   TOTEN)     ---> $d/F_ion-electron.dat (see above, 'ion-electron   TOTEN'='free  energy   TOTEN')"
 if [ "$(grep 'ML_' $d/INCAR)" == "" ]; then
  grep -h "free  energy   TOTEN" $ff | awk -v NN=$NN -v dt=$dt '{printf ("%.2f  %.8f\n", NR*dt, $(NF-1)/NN) }'    > $d/F.dat # TOTEN= F = U_el - TS_el = Pot + EENTRO   (EENTRO = -TS)
  grep -h "ion-electron   TOTEN" $ff | awk -v NN=$NN -v dt=$dt '{printf ("%.2f  %.8f\n", NR*dt, $(NF-2)/NN) }'    > $d/F_ion-electron.dat # Same as "free  energy   TOTEN"
 #==============  MACHINE LEARNING FREE ENERGIES ===============#
 else
  echo "    Machine Learning calculation                       ---> F.dat, F_ion-electron.dat, F_KS.dat" 
  if [ "$(grep "TOTAL-FORCE" $d/OUTCAR  | grep -v ML)" == "" ]; then echo "" > $d/F_KS.dat;
  else
  grep  -h 'POTIM\|Ionic step\|free  energy   TOTEN'  $ff  | awk  -v NN=$NN ' /POTIM = /{dt=$3; N+=nstep} /Ionic step/{nstep=$4} /free  energy   TOTEN/{F=$(NF-1);   printf ("%s  %.8f\n", (nstep+N-1)*dt, F/NN) }  '   > $d/F_KS.dat
  fi
  grep  -h 'POTIM\|Ionic step\|ion-electron   TOTEN'  $ff  | awk  -v NN=$NN ' /POTIM = /{dt=$3; N+=nstep} /Ionic step/{nstep=$4} /ion-electron   TOTEN/{F=$(NF-2);   printf ("%s  %.8f\n", (nstep+N-1)*dt, F/NN) }  '   > $d/F_ion-electron.dat

  grep -h "free  energy ML TOTEN" $ff | awk -v NN=$NN -v dt=$dt  '{printf ("%f  %.8f\n", NR*dt, $(NF-1)/NN) }'    > $d/F.dat # TOTEN= F = U_el - TS_el = Pot + EENTRO   (EENTRO = -TS)
 fi
 #==============================================================#

 #echo "Calculating Total Energy ETOTAL (Kin+F)"                            # Not very realistic, since it includes the smearing, which is non physical (ETOTAL = TOTEN + EKIN = F_el + <KIN>)
 #grep -h "ETOTAL" $ff | awk -v N=$NN '{print $5/N}'                       > $d/Etotal.dat   # This is the one that remains constant in NVE (microcanonical); BUT IT IS NOT THE <E> OF THE SYSTEM! (see E.dat). But good for benchmarks

 echo "Calculating total energy (Etotal= ETOTAL)             ---> $d/Etotal.dat  [ TOTEN+EKIN+ES+EPS (energy Etotal, includes thermostat)] "   # Not very realistic, since it includes the smearing, which is non physical (ETOTAL = TOTEN + EKIN = F_el + <KIN>)
 grep -h "total energy   ETOTAL" $ff | awk -v N=$NN '{print $(NF-1)/N}'   > $d/Etotal.dat    # ETOTAL= TOTEN + EKIN = F + EKIN = (U_el - TS_el) + K_ions. This is the one that remains constant in NVE (microcanonical); BUT IT IS NOT THE <E> OF THE SYSTEM! (see E.dat). But good for benchmarks

 echo "Calculating Energy Without Entropy (Pot)              ---> $d/Pot.dat"
 if [ "$(grep 'ML_' $d/INCAR)" == "" ]; then
  grep -h "energy  without entropy" $ff | awk -v N=$NN -v dt=$dt '{printf("%.2f  %.10f\n", NR*dt, $4/N)}' > $d/Pot.dat   # energy  without entropy (Pot =  F + TS = F - EENTRO ). This is the potential energy (NOT FREE ENERGY) of the system.
 else
  echo "    Machine Learning calculation                       ---> Pot.dat (same as TOTEN = F ), Pot_KS.dat (DFT) "
  grep -h "ML energy  without entropy" $ff | awk -v N=$NN -v dt=$dt '{printf("%10f  %.10f\n", NR*dt,$5/N)}'                 > $d/Pot.dat    # energy  without entropy = potential energy. 

  if [ "$(grep "TOTAL-FORCE" $d/OUTCAR  | grep -v ML)" == "" ]; then echo "" > $d/Pot_KS.dat;
  else
  grep  -h 'POTIM\|Ionic step\|energy  without entropy'  $ff  | awk  -v NN=$NN ' /POTIM = /{dt=$3; N+=nstep} /Ionic step/{nstep=$4} /energy  without entropy/ && !/ML/{Pot=$4;  printf ("%s  %.8f\n", (nstep+N-1)*dt, Pot/NN ) } ' $ff   > $d/Pot_KS.dat 
  fi
 fi




 # CANONICAL ENSEMBLE 
 if [ "`awk '{ if ( match($0,/SMASS/)!=0 && $3==0 && substr($0,1,1)!="#") print "NVT" }' $d/INCAR`" == "NVT" ]; then
  echo "Calculating TOTAL ENERGY (Kin+Pot) in NVT ensemble    ---> $d/E.dat"
  awk -v N=$N -v NN=$NN -v T=$tebeg -v kB=$kB '{U=$2; print $1, U + 1.5*N*kB*T/NN   }'     $d/Pot.dat > $d/E.dat   # Assuming equipartition <K>=3/2 N*kb*T (canonical)
  if grep -q 'ML_' "$d/INCAR"; then  # If Machine Learning
   EENTRO=`grep EENTRO $d/OUTCAR | tail -1 | awk '{print $NF}'`
   if [ "${EENTRO}" == "" ]; then EENTRO=`grep EENTRO $d/*/OUTCAR | tail -1 | awk '{print $NF}'`; fi  # Assume there is a directory inside $d with the DFT calculation
   echo "Subtracting EENTRO= $EENTRO to F to get U=F-EENTRO to obtain E= U  + 3/2*N*kB*T ---> E.dat"
   awk -v N=$N -v NN=$NN -v T=$tebeg -v kB=$kB -v EENTRO=$EENTRO '{F=$2; U=(F-EENTRO/NN); print $1, U  + 1.5*N*kB*T/NN ; }'     $d/Pot.dat > $d/E.dat   # Assuming equipartition <K>=3/2 N*kb*T (canonical), and Pot.dat= F.dat = TOTEN
   awk -v N=$N -v NN=$NN -v T=$tebeg -v kB=$kB '{U=$2; print $1, U + 1.5*N*kB*T/NN   }'     $d/Pot_KS.dat > $d/E_KS.dat   # Assuming equipartition <K>=3/2 N*kb*T (canonical)
  fi
  #awk -v N=$N -v T=$tebeg -v kB=$kB '{print $1/N + 1.5*N*kB*T/N }'     $d/Pot.dat > $d/E.dat   # Assuming equipartition <K>=3/2 N*kb*T (canonical) <--- E/atom
  echo "Correcting Pressure (using thermostat T)...                 press.dat ---> tot_press.dat (Thermostat temperature)"
  awk -v N=$N -v NN=$NN -v T=$tebeg -v V=$V -v kB=$kB '{toGPa=160.217662079999996649; print $1,$2+N*kB*T/V*toGPa}' $d/press.dat > $d/tot_press.dat             # Thermostat temperature
 
 # MICROCANONICAL ENSEMBLE 
 else
  echo "Calculating TOTAL ENERGY (Kin+Pot) in NVE ensemble     ---> $d/E.dat"
  paste $d/Kin.dat $d/Pot.dat | awk -v N=$N '{print $1+$2}'                      > $d/E.dat  # Instantaneous EKin+E_without_entropy
  echo "Correcting Pressure using instantaneous temperature...    press.dat --->    tot_press.dat"
  paste $d/press.dat $d/temp.dat | awk -v N=$N -v NN=$NN -v kB=$kB -v V=$V '{toGPa=160.217662079999996649; print $1+NN*kB*$2/V*toGPa}' > $d/tot_press.dat   # Instantaneous temperature
 fi



# paste temp.dat vol.dat > $d/TV.dat
# METHOD 1

#METHOD 2
# awk '{print '$kB'*'$N'*$1/$2}' temp.dat | head -n -1 > $d/diff.dat  # Instantaneous temperature
# awk '{print '$kB'*'$N'*'$tebeg'/$2}' TV.dat | head -n -1 > $d/diff.dat  # Thermostat mean temperature
# paste press.dat diff.dat | awk '{print $1+$2}' > $d/tot_press.dat
# rm TV.dat diff.dat
 #cd ..
 
 #echo "Adding Time column..."
 #dt=$(grep -h -m 1 'POTIM' $d/OUTCAR| awk '{print $3}')
 #files="$(echo `find $d/ -maxdepth 1  -iname '*.dat' -and -not -name "*_KS.dat" -mmin -1`)"
 #for dat in $files
 #do
 # awk -v dt=$dt '{print dt*(NR-1),$1}' $dat | column -t > tmp.tmp
 # mv tmp.tmp $dat
 #done
 
 


done

