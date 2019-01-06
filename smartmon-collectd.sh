#!/bin/bash

output_smart_attribute() {
	env_value="SMART_${1}"
	tmp=$env_value[*]
	if [ -z "${!tmp}" ]; then
		return
	fi
	tmp=$env_value[@]
	values=(${!tmp})
	echo "PUTVAL $HOST/smartmon$adp-$dsk$id/smart_attribute-$1 interval=$INTERVAL N:${values[0]}:${values[1]}:${values[2]}:${values[0]}"
}

output_typed() {
        env_value="SMART_${1}"
        tmp=$env_value[*]
        if [ -z "${!tmp}" ]; then
                return
        fi
        tmp=$env_value[@]
        values=(${!tmp})
	echo "PUTVAL $HOST/smartmon/$2$adp-$dsk$id-$1 interval=$INTERVAL N:${values[3]}"
}

for disk in "$@"; do
	alldisks="$alldisks $disk"
	disk=${disk%:*}
	if ! [ -e "/dev/$disk" ]; then
		echo "$(basename $0): disk /dev/$disk not found !" >&2
		exit 1
	fi
done

HOST=`hostname`
INTERVAL=300
while true; do
	{ for disk in $alldisks; do
		dsk=${disk%:*}
		drv=${disk#*:}
		id=""
		adp=""

		if [ "$disk" != "$drv" ]; then
			id=${drv#*,}
			adp="-${drv%,*}"
			drv="-d $drv"
		else
			drv=
		fi
		SMART_attributes=""
		eval `/usr/sbin/smartctl -n standby $drv -A "/dev/$dsk" \
			| awk '$3 ~ /^0x/ && $2 ~ /^[a-zA-Z0-9_-]+$/ { gsub(/-/, "_"); print "SMART_attributes=\"$SMART_attributes " $1 ":" $2 "\"; SMART_" $2 "=(" $4 " " $5 " " $6 " " $10 ")" }' 2>/dev/null`

                # Health status: 8 bits mask, read smartctl for meaning, anything > 0 is bad
		echo "PUTVAL $HOST/smartmon/gauge$adp-$dsk$id-health-status interval=$INTERVAL N:$?"

		for attr in $SMART_attributes; do
			attr_id=${attr%:*}
			attr_name=${attr#*:}
			if [ $attr_id = 1 -o $attr_id = 195 ]; then
				output_typed $attr_name disk_error
			elif [ $attr_id = 9 ]; then
				output_typed $attr_name smart_poweron
			elif [ $attr_id = 12 ]; then
				output_typed $attr_name smart_powercycles
			elif [ $attr_id = 194 ]; then
				output_typed $attr_name smart_temperature
			elif [ $attr_id = 196 -o $attr_id = 197 ]; then
				output_typed $attr_name smart_badsectors
			fi
			output_smart_attribute $attr_name
		done
	done } | socat - UNIX-CONNECT:/run/collectd-unixsock > /dev/null

	sleep $INTERVAL || true
done

