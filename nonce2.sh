#!/bin/bash

## GET BLOCKCHAIN DATA
COIN_NAME="sugarchain"
COIN_CLI="$HOME/git/SUGAR/WALLET/sugarchain-v0.16.3/src/sugarchain-cli"
COIN_OPTION="-rpcuser=username -rpcpassword=password -testnet"

BLOCKS=$($COIN_CLI $COIN_OPTION getblockcount)

START_BLOCK=$(expr 1 + $(tail -n1 nonce.csv | awk -F , '{print $1}'))

for i in `seq $START_BLOCK $BLOCKS`; do
	BLOCK_HASH=$($COIN_CLI $COIN_OPTION getblockhash $i)
	NONCE=$($COIN_CLI $COIN_OPTION getblock $BLOCK_HASH | jq .nonce)
	echo "$i,$NONCE" | tee -a $COIN_NAME.csv
done

## DRAW PLOT & LAUNCH QT
FILENAME="$COIN_NAME.csv"
gnuplot -persist <<-EOFMarker 
set terminal qt size 960,540 font "VL P Gothic,10"; \
set datafile separator ","; \
set title "Nonce Distribution ($COIN_NAME)"; \
set xlabel "Block Height"; \
set ylabel "Nonce"; \
set grid xtics ytics mxtics mytics; \
set nokey; \
plot "$FILENAME" using 1:2 with points pt 7 ps 0.3 lc rgb "black";
EOFMarker

