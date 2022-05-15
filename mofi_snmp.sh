#!/bin/sh
cmd=$1

export conversion=1024
month=$(date +%b)
interface="br-lan"

DEVICE=/dev/modem

case "$cmd" in
	lte_mode)
		INFO=$(scmd '!GSTATUS?' $DEVICE 0 2>/dev/null)

		lte_mode="unknown"
		echo "$INFO" | grep WCDMA >/dev/null && lte_mode="WCDMA"
		echo "$INFO" | grep "LTE band:" >/dev/null && lte_mode="LTE"
		echo "$lte_mode"
		;;
	lte_band)
		INFO=$(scmd '!GSTATUS?' $DEVICE 0 2>/dev/null)

		echo "$INFO" | grep "LTE band:" >/dev/null
		if [ "$?" != "0" ]
		then
			echo "invalid"
			return
		fi

		# LTE B4, B7, etc
		BAND=$(echo "$INFO" |  grep 'LTE band:' | sed 's/.*:\[//g;s/\]//g' | sed 's/LTE band: //g' | awk -F ' ' '{print $1}')
		if [ -z "$BAND" ]; then
			BAND="NF"
		fi
		echo "$BAND"
		;;
	lte_rssi)
		INFO=$(scmd '!GSTATUS?' $DEVICE 0 2>/dev/null)

		echo "$INFO" | grep "LTE band:" >/dev/null
		if [ "$?" != "0" ]
		then
			echo "invalid"
			return
		fi

		RSRP=$(echo "$INFO" | grep -m 1 'PCC RxM RSSI' | awk -F ' ' '{print $4}' | sed 's/.*:\[//g;s/\]//g')
		if [ -z "$RSRP" ]; then
			RSRP=$(echo "$INFO" | grep -m 2 'RSRP (dBm)'  | sed -n '1{p;q}' | awk -F ' ' '{print $4}' | sed 's/.*:\[//g;s/\]//g')
		fi

		[ -z "$RSRP" ] && RSRP="unknown"
		echo "$RSRP"
		;;
	lte_rsrp)
		INFO=$(scmd '!GSTATUS?' $DEVICE 0 2>/dev/null)

		echo "$INFO" | grep "LTE band:" >/dev/null
		if [ "$?" != "0" ]
		then
			echo "invalid"
			return
		fi

		RSRP=$(echo "$INFO" | grep -m 1 'PCC RxM RSSI' | awk -F ' ' '{print $7}' | sed 's/.*:\[//g;s/\]//g')
		if [ -z "$RSRP" ]; then
			RSRP=$(echo "$INFO" | grep -m 2 'RSRP (dBm)'  | sed -n '1{p;q}' | awk -F ' ' '{print $7}' | sed 's/.*:\[//g;s/\]//g')
		fi

		[ -z "$RSRP" ] && RSRP="unknown"
		echo "$RSRP"
		;;
	lte_rsrq)
		INFO=$(scmd '!GSTATUS?' $DEVICE 0 2>/dev/null)

		echo "$INFO" | grep "LTE band:" >/dev/null
		if [ "$?" != "0" ]
		then
			echo "invalid"
			return
		fi

		RSRQ=$(echo "$INFO" | grep -m 1 'RSRQ' | awk -F ' ' '{print $3}')

		[ -z "$RSRQ" ] && RSRQ="unknown"

		echo "$RSRQ"
		;;
	lte_current_carrier)
		carrier=$(scmd "+COPS?" | grep "^1:" | cut -d ":" -f 3 | cut -d "," -f 3 | sed -e 's/"//g')
		[ -z "$carrier" ] && carrier="unknown"
		echo "$carrier"
		;;
        lte_usage)
		units=$(vnstat -i $interface --short | grep $month | awk '{ print $10 }')

		if [ $units = "MiB" ]; then
		    export conversion=1
		fi

                usage=$(vnstat -i $interface --short | grep $month | awk -v conv=$conversion '{ print $9 * conv }')
                echo "$usage"
                ;;
	*)
		echo "unknown"
		;;
esac
