vlib work

vlog -timescale 1ns/1ns pong_graphics.v

vsim control

log {/*}

add wave {/*}

# Clock
force {clk} 0 0, 1 20 -repeat 40
force {resetn} 0
run 40ns

force {resetn} 1
force {go} 1
run 40ns

force {go} 1
run 40ns

force {go} 1
run 40ns

force {go} 1
run 40ns