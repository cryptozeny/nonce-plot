#!/bin/bash
## getNonce

## GET FROM RPC
COIN_CLI="$HOME/git/SUGAR/WALLET/sugarchain-v0.16.3/src/sugarchain-cli"
COIN_OPTION="-rpcuser=username -rpcpassword=password -testnet" # MAIN: nothing | TESTNET: -testnet | REGTEST: -regtest
GET_INFO="$COIN_CLI $COIN_OPTION"
GET_TOTAL_BLOCK_AMOUNT=$($GET_INFO getblockcount)

CHAIN_TYPE=$( $GET_INFO getblockchaininfo | jq -r '[.chain] | "\(.[0])"' )

COIN_NAME="$CHAIN_TYPE.Sugarchain(t$BLOCK_TIME)"
POW_NAME="YP"
DIFF_NAME="DS"
DIFF_N_SIZE="510"

NONCE_FILE_NAME="NONCE-$COIN_NAME-$POW_NAME-$DIFF_NAME(n$DIFF_N_SIZE).csv"

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
	$GET_INFO getblock $($GET_INFO getblockhash $BLOCK_COUNT) | jq -r '[.height, .time, .nonce] | "\(.[0]) \(.[1]) \(.[2])"' | tee -a $NONCE_FILE_NAME
done

## DRAW PLOT & LAUNCH QT
gnuplot -persist <<-EOFMarker 
set title "$NONCE_FILE_NAME"; set terminal qt size 960,540 font "VL P Gothic,10"; \
set xlabel "Block Height"; \
set ylabel "Nonce"; \
set xrange [-510:*]; set xtics 510*2 rotate by 45 right; \
set xtics add ("GENESIS" 0) ("N+1=511" 511); \
set yrange [-250000000:*]; set ytics 250000000; \
set grid xtics ytics mxtics mytics; \
set nokey; \
plot "$NONCE_FILE_NAME" using 0:3 with points pt 7 ps 0.3 lc rgb "black";
EOFMarker
