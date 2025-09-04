# VASP-scripts
This repository contains a collection of Bash utilities to post-process and analyze VASP simulation outputs.
The scripts are designed to simplify the extraction of thermodynamic and statistical information from DFT molecular dynamics and static calculations performed with VASP.

## Documentation

Check my [wiki page](https://github.com/fgonzcat/VASP-scripts/wiki/)

## 📂 Available Scripts


### 🔹 [get-TP(t).sh](https://github.com/fgonzcat/VASP-scripts/wiki/get-TP(t).sh)
Obtain **Temperature, Pressure, and Energies** as a function of time from MD simulations: $T(t)$, $E(t)$, $P(t)$.   
Generates a suite of `.dat` files with averages of key thermodynamic quantities:




### 🔹 [Convergence Test](https://github.com/fgonzcat/VASP-scripts/wiki/convergence)
Analyze the convergence behavior of running averages such as free energy (`F_ev.dat`) or pressure (`tot_press_ev.dat`).  
- Fits the data to an exponential relaxation model  
- Computes a **Convergence Quality (%)**  
- Estimates the step at which convergence is achieved  


