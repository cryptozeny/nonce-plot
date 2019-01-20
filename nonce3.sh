#!/bin/bash
## getNonce

## GET FROM RPC
COIN_CLI="$HOME/git/SUGAR/WALLET/sugarchain-v0.16.3/src/sugarchain-cli"
COIN_OPTION="-rpcuser=username -rpcpassword=password -testnet" # MAIN: nothing | TESTNET: -testnet | REGTEST: -regtest
GET_INFO="$COIN_CLI $COIN_OPTION"
GET_TOTAL_BLOCK_AMOUNT=$($GET_INFO getblockcount)
# GET_TOTAL_BLOCK_AMOUNT=510 # test

CHAIN_TYPE=$( $GET_INFO getblockchaininfo | jq -r '[.chain] | "\(.[0])"' )

COIN_NAME="$CHAIN_TYPE.Sugarchain(t$BLOCK_TIME)"
POW_NAME="YP"
DIFF_NAME="DS"
DIFF_N_SIZE="510"

NONCE_FILE_NAME="NONCE-$COIN_NAME-$POW_NAME-$DIFF_NAME(n$DIFF_N_SIZE).csv"

# POW_LIMIT="1.192074847720173e-07"
POW_LIMIT=$( $GET_INFO getblock $($GET_INFO getblockhash 0) | jq -r '[.difficulty] | "\(.[0])"' )

# check COIN_CLI
if [ ! -e $COIN_CLI ]; then
    echo "ERROR: NO COIN_CLI: $COIN_CLI"
    exit 1
fi

# new? or continue?
if [ ! -e $NONCE_FILE_NAME ]; then
    # echo "NEW: $NONCE_FILE_NAME"
    echo -e "\e[32mNEW: \t$NONCE_FILE_NAME\e[39m"
    # START_BLOCK=1
    START_BLOCK=0 # from genesis
else 
    # echo "CONTINUE: $NONCE_FILE_NAME"
    echo -e "\e[36mKEEP: \t$NONCE_FILE_NAME\e[39m"
    START_BLOCK=$(( $( tail -n1 $NONCE_FILE_NAME | awk '{print $1}' ) + 1 ))
    echo -e "\e[36mCONTINUE FROM $START_BLOCK\e[39m"
fi 

# loop
for BLOCK_COUNT in `seq $START_BLOCK $GET_TOTAL_BLOCK_AMOUNT`; 
do
	$GET_INFO getblock $($GET_INFO getblockhash $BLOCK_COUNT) | jq -r '[.height, .time, .nonce, .difficulty] | "\(.[0]) \(.[1]) \(.[2]) \(.[3])"' | tee -a $NONCE_FILE_NAME
done

## DRAW PLOT & LAUNCH QT
gnuplot -persist <<-EOFMarker 
set title "$NONCE_FILE_NAME" offset -43; set terminal qt size 1200,600 font "VL P Gothic,10";
set label 1 "LIMIT = $POW_LIMIT" at graph 0.78, 1.03;
set label 2 "BLOCKS = $GET_TOTAL_BLOCK_AMOUNT" at graph 0.78, 1.06;
set xrange [0:*]; set xlabel "Block Height"; set xtics 510*4 rotate by 45 right; set xtics add ("GENESIS" 0) ("N+1=511" 511);
set yrange [0:8.5e+08*5]; set ylabel "Nonce"; set ytics 8.5e+08; set format y '%.4g'; set ytics nomirror;
set y2range [$POW_LIMIT:$POW_LIMIT*5]; set y2label "Difficulty"; set format y2 '%.4g'; set y2tics $POW_LIMIT, $POW_LIMIT/2.5;
set grid xtics ytics mxtics mytics;
set key top left; set key box opaque;
plot \
"$NONCE_FILE_NAME" using 0:3 axis x1y1 w p title "Nonce" pt 7 ps 0.3 lc rgb "black", \
"$NONCE_FILE_NAME" using 0:4 axis x1y2 w l title "Difficulty" lc rgb "red" lw 1.25,
EOFMarker
