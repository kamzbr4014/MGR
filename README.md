# Master Thesis project

## Software  
This project is devlop in Xilinx Vivado DS. To simplyfy git usage in project mode, we are using [script](https://github.com/barbedo/vivado-git). To recreate project in Vivado please do following steps:  
- Run your Vivado GUI,
- Go to Tools, then selsct Run Tcl Script,
- Select .tcl file in main repository folder.

## Run tests  
Validation tests are wrote in Matlab. For now, there are coverage for:
- Preprocessor module (preprocessing module is temporary unavailable),
- Filter module (all structures)  .

To run test follow these steps:
1. Generate frame file in `dci_frame_gen.m`:  
Set path to test image and filter ordet, then run script.  
2. Generate filter coefficients in `coeff_gen.m`:  
Set filter order and optional variables. For now file generate only coefficients for Gaussian filter. Run script to generate file.  
3. In Vivado DS run simulation for selected module:  
For filter module - `test_filter_bd`. Test should end with message `Failure: Test: OK` ( ¯\_(ツ)_/¯ ).
4. Run proper validation script in matlab:  
For filter test - `filter_valid.m`. Displayed window should look like this:  
<p align="center">
<img src="https://user-images.githubusercontent.com/47113343/119718390-ccb11b80-be67-11eb-8bfc-de7b501b78ca.jpg" width="400" height="225">
</p>  
