#!/bin/sh
iptables -I forwarding_rule -m comment --comment "shut off computer1" -p all -m mac --mac-source 33:33:33:33:33:33 -j REJECT
iptables -I forwarding_rule -m comment --comment "shut off device1" -p all -m mac --mac-source 44:44:44:44:44:44 -j REJECT
