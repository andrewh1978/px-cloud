masters=$(grep master hosts | cut -f 2 -d " ")
for m in $masters; do
  ip=$(vagrant ssh $m -c "curl http://ipinfo.io/ip" 2>/dev/null)
  echo $m $ip
done
