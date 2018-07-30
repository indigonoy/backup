#Create a simulator object
set ns [new Simulator]

#Define different colors for data flows (for NAM)
$ns color 1 Blue
$ns color 2 Red

#Open the NAM trace file
set nf [open queue-out.nam w]
$ns namtrace-all $nf

#Open the Trace file
set tf [open queue-out.tr w]
$ns trace-all $tf

#Open the Queue trace files
set queue_size [open queue-size.tr w]
set queue_band [open queue-band.tr w]
set queue_lost [open queue-drop.tr w]

#Define a 'finish' procedure
proc finish {} {
        global ns nf tf queue_size queue_band queue_lost

        $ns flush-trace

        #Close the NAM trace file
        close $nf

        #Close the Trace file
        close $tf

        close $queue_size
        close $queue_band
        close $queue_lost

        #Execute NAM on the trace file
        #exec nam queue-out.nam &
        exit 0
}

#Create four nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

#Create links between the nodes
$ns duplex-link $n0 $n2 2Mb 10ms DropTail
$ns duplex-link $n1 $n2 2Mb 10ms DropTail
$ns duplex-link $n2 $n3 1.7Mb 20ms DropTail

#Set Queue Size of link (n2-n3) to 10
$ns queue-limit $n2 $n3 10

#Give node position (for NAM)
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n2 orient right-up
$ns duplex-link-op $n2 $n3 orient right

#Monitor the queue for link (n2-n3). (for NAM)
$ns duplex-link-op $n2 $n3 queuePos 0.5

#Setup a TCP connection
set tcp [new Agent/TCP]
$tcp set class_ 2
$ns attach-agent $n0 $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n3 $sink
$ns connect $tcp $sink
$tcp set fid_ 1

#Setup a FTP over TCP connection
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP

#Setup a UDP connection
set udp [new Agent/UDP]
$ns attach-agent $n1 $udp
set null [new Agent/Null]
$ns attach-agent $n3 $null
$ns connect $udp $null
$udp set fid_ 2

#Setup a CBR over UDP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 1mb
$cbr set random_ false

# Set Queue Moniroting
set qmon [$ns monitor-queue $n2 $n3 [open queue-mon w] 0.05]
[$ns link $n2 $n3] queue-sample-timeout
#[$ns link $n2 $n3] start-tracing

proc record { } {
	global ns qmon queue_size queue_band queue_lost n2 n3
	
	set time 0.05
	set now [$ns now]

	$qmon instvar parrivals_ pdepartures_ bdrops_ bdepartures_ pdrops_ 
	puts $queue_size "$now [expr $parrivals_-$pdepartures_-$pdrops_]"
	puts $queue_band   "$now [expr $bdepartures_*8/1024/$time]"
	set bdepartures_ 0                                
	puts $queue_lost "$now [expr $pdrops_/$now]"
#	puts $queue_lost "$now [expr $pdrops_]"
	$ns at [expr $now+$time] "record"
	#puts $parrivals_
}

#Schedule events for the CBR and FTP agents
$ns at 0.1 "record"
$ns at 0.1 "$cbr start"
$ns at 1.0 "$ftp start"
$ns at 4.0 "$ftp stop"
$ns at 4.5 "$cbr stop"

#Detach tcp and sink agents (not really necessary)
$ns at 4.5 "$ns detach-agent $n0 $tcp ; $ns detach-agent $n3 $sink"

#Call the finish procedure after 5 seconds of simulation time
$ns at 5.0 "finish"

#Print CBR packet size and interval
puts "CBR packet size = [$cbr set packet_size_]"
puts "CBR interval = [$cbr set interval_]"

#Run the simulation
$ns run

