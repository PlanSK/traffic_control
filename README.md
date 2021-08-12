traffic from LAN (enp0s8) is egress for client (DST) 

{WLAN}enp0s3 <--> enp0s8{LAN} (tc rules to LAN) --> client (DST)

{WLAN}enp0s3 <--> (tc rules to WLAN) ifb0 <--@ enp0s8{LAN} <-- client (SRC)
