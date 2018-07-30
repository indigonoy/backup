
# ======================================================================
# Defone options
# ======================================================================
set opt(chan)           Channel/WirelessChannel  ;# channel type
set opt(prop)           Propagation/TwoRayGround ;# radio-propagation model
set opt(netif)          Phy/WirelessPhy          ;# network interface type
set opt(mac)            Mac/802_11               ;# MAC type
set opt(ifq)            Queue/DropTail/PriQueue  ;# interface queue type
set opt(ll)             LL                       ;# link layer type
set opt(ant)            Antenna/OmniAntenna      ;# antenna model
set opt(ifqlen)         50                       ;# max packet in ifq
set opt(nn)             9                        ;# number of mobilenodes
set opt(adhocRouting)   OLSR                     ;# routing protocol

set opt(cp)             ""                       ;# connection pattern file
set opt(sc)             ""                       ;# node movement file.

set opt(x)              1000                      ;# x coordinate of topology
set opt(y)              1000                      ;# y coordinate of topology
set opt(seed)           0.0                      ;# seed for random number gen.
set opt(stop)           30                       ;# time to stop simulation

set opt(cbr-start)      0.0
# ============================================================================
#
# check for random seed
#
if {$opt(seed) > 0} {
puts "Seeding Random number generator with $opt(seed)\n"
ns-random $opt(seed)
}
#
# create simulator instance
#
set ns_ [new Simulator]
#
# control OLSR behaviour from this script -
# commented lines are not needed because
# those are default values
#
Agent/OLSR set use_mac_ true
#Agent/OLSR set debug_ false
#Agent/OLSR set willingness 3
#Agent/OLSR set hello_ival_ 2
#Agent/OLSR set tc_ival_ 5
#
# open traces
#
set tracefd [open olsr_count.tr w]
set namtrace [open olsr_count.nam w]
$ns_ trace-all $tracefd
$ns_ namtrace-all-wireless $namtrace $opt(x) $opt(y)
#
# create topography object
set topo [new Topography]
#
# define topology
#
$topo load_flatgrid $opt(x) $opt(y)
#
# create God
#
create-god $opt(nn)

set chan_1_ [new $opt(chan)]

#
# configure mobile nodes
#
$ns_ node-config -adhocRouting $opt(adhocRouting) \
		-llType $opt(ll) \
		-macType $opt(mac) \
		-ifqType $opt(ifq) \
		-ifqLen $opt(ifqlen) \
		-antType $opt(ant) \
		-propType $opt(prop) \
		-phyType $opt(netif) \
		-channel $chan_1_ \
		-topoInstance $topo \
		-wiredRouting OFF \
		-agentTrace ON \
		-routerTrace ON \
		-macTrace OFF


#Phy/WirelessPhy set CSTresh_ 3.07645e-07

#Phy/WirelessPhy set bandwidth_ 11Mb;
#Mac/802_11 set dataRate_ 11Mb;
#Mac/802_11 set basicRate_ 512Kb;
#Phy/WirelessPhy set freq_ 2.4e+9
Phy/WirelessPhy set bandwidth_ 54Mb;
Mac/802_11 set dataRate_ 11Mb;
Mac/802_11 set basicRate_ 512Kb;

#Application/Traffic/CBR set rate_ 11Mb
#Application/Traffic/CBR set packetSize_ 11534336

for {set i 0} {$i < $opt(nn)} {incr i} {
set node_($i) [$ns_ node]
}


#
# define initial node position in nam
#

#
# positions
#


$node_(0) set X_ 350.0
$node_(0) set Y_ 800.0
$node_(0) set Z_ 0.0 

$node_(1) set X_ 150.0 
$node_(1) set Y_ 750.0
$node_(1) set Z_ 0.0
 
$node_(2) set X_ 550.0
$node_(2) set Y_ 850.0
$node_(2) set Z_ 0.0 

$node_(3) set X_ 340.0
$node_(3) set Y_ 600.0
$node_(3) set Z_ 0.0

$node_(4) set X_ 630.0
$node_(4) set Y_ 650.0
$node_(4) set Z_ 0.0 

$node_(5) set X_ 450.0
$node_(5) set Y_ 420.0
$node_(5) set Z_ 0.0

$node_(6) set X_ 250.0
$node_(6) set Y_ 180.0
$node_(6) set Z_ 0.0

$node_(7) set X_ 470.0
$node_(7) set Y_ 200.0
$node_(7) set Z_ 0.0

$node_(8) set X_ 650.0 
$node_(8) set Y_ 320.0
$node_(8) set Z_ 0.0


#
#
for {set i 0} {$i < $opt(nn)} {incr i} {
	$ns_ initial_node_pos $node_($i) 20
}

#
# setup UDP connection
set udp [new Agent/UDP]
set null [new Agent/Null]
$ns_ attach-agent $node_(1) $udp
$ns_ attach-agent $node_(6) $null
$ns_ connect $udp $null
set cbr [new Application/Traffic/CBR]
$cbr set packetSize_ 512
$cbr set rate_ 512Kb
$cbr attach-agent $udp
$ns_ at $opt(cbr-start) "$cbr start"
#
# print (in the trace file) routing table and other
# internal data structures on a per-node basis
#

$ns_ at 10.0 "[$node_(0) agent 255] print_rtable"
$ns_ at 15.0 "[$node_(0) agent 255] print_linkset"
$ns_ at 20.0 "[$node_(0) agent 255] print_nbset"
$ns_ at 25.0 "[$node_(0) agent 255] print_nb2hopset"
$ns_ at 30.0 "[$node_(0) agent 255] print_mprset"
$ns_ at 30.0 "[$node_(1) agent 255] print_mprset"
$ns_ at 30.0 "[$node_(2) agent 255] print_mprset"
$ns_ at 30.0 "[$node_(3) agent 255] print_mprset"
$ns_ at 30.0 "[$node_(4) agent 255] print_mprset"
$ns_ at 30.0 "[$node_(5) agent 255] print_mprset"
$ns_ at 30.0 "[$node_(6) agent 255] print_mprset"
$ns_ at 30.0 "[$node_(7) agent 255] print_mprset"
$ns_ at 30.0 "[$node_(8) agent 255] print_mprset"
$ns_ at 30.0 "[$node_(0) agent 255] print_mprselset"
$ns_ at 30.0 "[$node_(0) agent 255] print_topologyset"
#
# source connection-pattern and node-movement scripts
#
if { $opt(cp) == "" } {
puts "*** NOTE: no connection pattern specified."
set opt(cp) "none"
} else {
puts "Loading connection pattern..."
source $opt(cp)
}
if { $opt(sc) == "" } {
puts "*** NOTE: no scenario file specified."
set opt(sc) "none"
} else {
puts "Loading scenario file..."
source $opt(sc)
puts "Load complete..."
}
#
# tell all nodes when the simulation ends
#
for {set i 0} {$i < $opt(nn) } {incr i} {
	$ns_ at $opt(stop) "$node_($i) reset";
}
$ns_ at $opt(stop) "puts \"NS EXITING...\" ; $ns_ halt"
$ns_ at $opt(stop) "stop"

proc stop {} {
	global ns_ tracefd namtrace
	$ns_ flush-trace
	close $tracefd
	close $namtrace
}
puts "Starting Simulation..."
$ns_ run
