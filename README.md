# smartmon-collectd

A script that collects SMART data for collectd

## Description

`collectd` includes a [plugin](https://collectd.org/wiki/index.php/Plugin:SMART) for monitoring SMART devices. The plugin has several limitations. To overcome some of them Samuel Behan has developed [a script](https://github.com/exoscale/collectd-smartmon) that uses `smartctl` to retrieve the values and can be invoked from `collectd`'s exec plugin. However, this approach causes several problems with SELinux on Fedora and CentOS.

The script provided here therefore takes a different approach. It runs independently from `collectd` and sends the data to `collectd` using `collectd`'s [unix socket](https://collectd.org/wiki/index.php/Plugin:UnixSock). The script can therefore run with root privileges

## Requirements

* smartmontools installed (and smartctl binary)

## Parameters

    <disk>[:<driver>,<id> ] ...

