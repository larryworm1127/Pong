rm -rf work
vlib work
vlog components.v tb_all.v
vsim tb_all
#log all signals and add some signals to waveform window
log {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}
run 8000ns