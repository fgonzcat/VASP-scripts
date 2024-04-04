# VASP-scripts
Shell scripts to analyze VASP simulations (mostly MD)

```
Obtain the Temperature, Pressure, and Energies as a function of time from MD simulations [Berkeley 05-21-18]

It creates the table with average energy, pressure, temperature, density, etc.

Usage: /home/fgonzalez/scripts/get-TP(t).sh  T-*
Usage: /home/fgonzalez/scripts/get-TP(t).sh  T-{25,30,53}00
Usage: /home/fgonzalez/scripts/get-TP(t).sh  Fe206

SUMMARY OF THE FILES GENERATED
================================
Kin.dat                    ---> EKIN
press.dat                  ---> 'external pressure' (just external, no ideal gas correction)
totpress.dat               ---> external + ideal gas correction (instant. T)
  press_KS.dat             ---> In machine learning, 'external pressure' (just Kohn-Sham, DFT pressures)
  totpress_KS.dat          ---> In machine learning, external + ideal gas correction with instant. T (just Kohn-Sham, DFT pressures)
F.dat                      ---> TOTEN= F = U_el - TS_el = Pot + EENTRO   [EENTRO = -TS]).
                                In machine learning, 'free  energy ML TOTEN' and TOTEN=Pot because F= ion-electron TOTEN = ML energy  without entropy = Pot.dat
  F_KS.dat                 ---> In machine learning, 'free  energy   TOTEN' (just Kohn-Sham, DFT TOTEN)
F_ion-electron.dat         ---> The 'see above ion-electron   TOTEN'  =  'free  energy   TOTEN') (In ML, contains both KS and ML TOTEN combined)
Etotal.dat                 ---> ETOTAL= TOTEN+EKIN+ES+EPS (energy Etotal, includes thermostat)]
Pot.dat                    ---> 'energy  without entropy'
                                 In machine learning, 'ML energy  without entropy' and Pot.dat = F.dat = TOTEN' [so, it DOES contain entropy... misnomer]
  Pot_KS.dat               ---> In machine learning, 'energy  without entropy' (just Kohn-Sham, DFT energies)
E.dat                      ---> <E> = 3/2 NkT + 'energy  without entropy' = Actual thermodynamic total energy
```
