vlib work
vlog location_processor.v tb_locationProcessor.v
vsim tb_locationProcessor
#log all signals and add some signals to waveform window
log {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}
run 500ns