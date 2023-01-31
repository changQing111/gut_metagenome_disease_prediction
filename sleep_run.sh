t=3
LIST=$1
MYPATH=/home/ubuntu
n=`wc -l $LIST | cut -f1 -d" " `

for i in `cat $LIST`
do
    let s++
    bash $MYPATH/sketch.sh $i &
    if [ $s -eq $t ]
    then
        break
    fi
done

sleep 60

let n-=$t
for i in `tail -n $n $LIST`
do
    while true
    do
       NUM=`ps -ef | grep "sketch\.sh" | grep -v "grep" | wc -l`
       if [ $NUM -ge $t ]
       then
           sleep 60
       else
           bash $MYPATH/sketch.sh $i &
           break
       fi
   done
done
