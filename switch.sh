CH=$1
RES=`grep $CH mq1.json`
if [ "$RES" != "" ]
then
 echo "Nothing to Do!\n"
 exit 1
fi
if [ "$1" == "TLS3" ]
then
 sed -i '' 's/TLS4/TLS3/g' mq1.json 
else
 sed -i '' 's@TLS3@TLS4@g' mq1.json 
fi

