create_clock -name clk -period 20.0 [get_ports clk]

create_generated_clock -name clk_div -source [get_ports clk] \
                       -divide_by 50000000 \
                       [get_ports clk_1hz_out]

create_generated_clock -name fast_clk -source [get_ports clk] \
                       -divide_by 50000 \
                       [get_ports clk_1khz_out]
