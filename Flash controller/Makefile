#MakeFile
#Final Project: NAND FLASH CONTROLLER VERIFICATION
#Author: Rajesh Ceervi, Lokesh Astakar Madhu, Vinod Sake

all:clean setup compile test

setup:
	vlib work
	vmap work work

compile:
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/Acounter.v
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/checker.sv
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/coverage.sv
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/ErrLoc.v
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/flash_bfm.sv
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/flash_interface.sv
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/flash_pkg.sv
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/H_gen.v
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/MFSM.v
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/mybuf.sv
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/nfcm_top.v
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/scoreboard.sv
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/tester.sv
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/TFSM.v
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/top.sv
	vlog +incdir+./src /u/crajesh/Desktop/Flash controller/testbench.sv

TestGen:
	vopt +acc top -o top_opt
#Without coverage
#	vsim top_opt
#With coverage
	vsim coverage top_opt

clean:
	rm -rf work transcript *~ vsim.wlf *.log dgs.dbg dmslogdir
