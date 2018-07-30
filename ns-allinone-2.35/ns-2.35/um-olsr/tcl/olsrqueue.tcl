
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
set opt(nn)             2                        ;# number of mobilenodes
set opt(adhocRouting)   OLSR                     ;# routing protocol

set opt(cp)             ""                       ;# connection pattern file
set opt(sc)             ""                       ;# node movement file.

set opt(x)              300                      ;# x coordinate of topology
set opt(y)              300                      ;# y coordinate of topology
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
Agent/OLSR set debug_   false

#
# control OLSR behaviour from this script -
# commented lines are not needed because
# those are default values
#
Agent/OLSR set use_mac_ true
#Agent/OLSR set debug_ true
#Agent/OLSR set willingness 3
#Agent/OLSR set hello_ival_ 2
#Agent/OLSR set tc_ival_ 5
#
# open traces
#
set tracefd [open olsr_count.tr w]
set namtrace [open olsr_count.nam w]
set queue_size [open queue-size.tr w]
set queue_band [open queue-band.tr w]
set queue_lost [open queue-drop.tr w]

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


#Phy/WirelessPhy set bandwidth_ 11Mb;
#Mac/802_11 set dataRate_ 11Mb;
#Mac/802_11 set basicRate_ 1Mb;

Phy/WirelessPhy set bandwidth_ 11Mb;
Mac/802_11 set dataRate_ 1Mb;
Mac/802_11 set basicRate_ 1Mb;
#Phy/WirelessPhy set L_ 1.0
#Application/Traffic/CBR set rate_ 11Mb;
#Application/Traffic/CBR set packetSize_ 1000

#Application/Traffic/CBR set rate_ 11Mb;
#Application/Traffic/CBR set packetSize_ 1000


for {set i 0} {$i < $opt(nn)} {incr i} {
set node_($i) [$ns_ node]
}


#
# define initial node position in nam
#

#
# positions
#
#$ns_ duplex-link $node_(0) $node_(1) 11Mb 2ms DropTail

$node_(0) set X_ 50.0
$node_(0) set Y_ 50.0
$node_(0) set Z_ 0.0 

$node_(1) set X_ 200.0 
$node_(1) set Y_ 50.0
$node_(1) set Z_ 0.0

#$node_(2) set X_ 350.0 
#$node_(2) set Y_ 200.0
#$node_(2) set Z_ 0.0

#$node_(1) set X_ 200.0 
#$node_(1) set Y_ 200.0
#$node_(1) set Z_ 0.0
 
#$node_(2) set X_ 350.0
#$node_(2) set Y_ 200.0
#$node_(2) set Z_ 0.0 

#
#
$ns_ duplex-link $node_(0) $node_(1) 1Mb 10ms DropTail
$ns_ queue-limit $node_(0) $node_(1) 5
$ns_ duplex-link-op $node_(0) $node_(1) queuePos 0.5

for {set i 0} {$i < $opt(nn)} {incr i} {
	$ns_ initial_node_pos $node_($i) 20
}
$ns_ trace-queue $node_(0) $node_(1)
#
# setup UDP connection
set udp [new Agent/UDP]
set null [new Agent/Null]
$ns_ attach-agent $node_(0) $udp
$ns_ attach-agent $node_(1) $null
$ns_ connect $udp $null
set cbr [new Application/Traffic/CBR]
$cbr set packetSize_ 512
#$cbr set rate_ 11Mb
$cbr set rate_ 1Mb
$cbr attach-agent $udp
$ns_ at $opt(cbr-start) "$cbr start"
#
# print (in the trace file) routing table and other
# internal data structures on a per-node basis
#
set qmon [$ns_ monitor-queue $node_(0) $node_(1) [open queue-mon w] 0.05]
[$ns_ link $node_(0) $node_(1)] queue-sample-timeout
#[$ns_ link $node_(0) $node_(1)] start-tracing

proc record { } {
	#global ns_ qmon queue_size queue_band queue_lost 
	global ns_ qmon queue_size queue_band queue_lost n0 n1
	
	set time 0.05
	set now [$ns_ now]
	$qmon instvar  pdrops_ pdepartures_ parrivals_ brops_ bdepartures_ barrivals_
	puts $queue_size "$now [expr $parrivals_-$pdepartures_-$pdrops_]"
	puts $queue_band   "$now [expr $bdepartures_*8/1024/$time]"
	set bdepartures_ 0
	puts $queue_lost "$now [expr $pdrops_/$now]"
	$ns_ at [expr $now+$time] "record"
	#set parr [$qmon set parrivals_];
	puts $parrivals_

}
$ns_ at 0.1 "record"

$ns_ at 10.0 "[$node_(0) agent 255] print_rtable"
$ns_ at 15.0 "[$node_(0) agent 255] print_linkset"
$ns_ at 20.0 "[$node_(0) agent 255] print_nbset"
$ns_ at 25.0 "[$node_(0) agent 255] print_nb2hopset"
$ns_ at 30.0 "[$node_(0) agent 255] print_mprset"
$ns_ at 35.0 "[$node_(0) agent 255] print_mprselset"
$ns_ at 40.0 "[$node_(0) agent 255] print_topologyset"
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
	global ns_ tracefd namtrace queue_size queue_band queue_lost
	$ns_ flush-trace
	close $tracefd
	close $namtrace
	close $queue_size
	close $queue_band
	close $queue_lost
	exit 0
}
puts "Starting Simulation..."
$ns_ run
