alias leases="[ -f /var/lib/misc/dnsmasq.leases -a \`cat /var/lib/misc/dnsmasq.leases | wc -l\` -gt 0 ] && cat /var/lib/misc/dnsmasq.leases || echo \"There's no lease\""
alias firewall="sudo /etc/init.d/S45firewall status"
