LIST=$1
MYPATH=/home/ubuntu
n=`wc -l $LIST | cut -f1 -d" " `

for i in `cat $LIST`
do
    let s++
    bash $MYPATH/sketch_2.sh $i &
    if [ $s -eq 3 ]
    then
        break
    fi
done

sleep 100

let n-=3
for i in `tail -n $n $LIST`
do
    while true
    do
       NUM=`ps -ef | grep "sketch_2\.sh" | grep -v "grep" | wc -l`
       if [ $NUM -ge 3 ]
       then
           sleep 60
       else
           bash $MYPATH/sketch_2.sh $i &
           break
       fi
   done
done
