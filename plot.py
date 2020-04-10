#! /usr/bin/env python
import matplotlib
matplotlib.use('Agg')
import re
import numpy as np
import matplotlib.pyplot as plt
import sys

def parse(s):
    mo = re.match (".*]\ *(\d+.\d+)-\ *(\d+.\d+) sec\ *(\d+.\d+ M|\d+\.?\d* K)Bytes\ *(\d+.\d+) Mbits/sec\ *(\d+.\d+) ms\ *(\d+)/\ *(\d+) \((\d+\.?\d*)%\)", s)
    if mo: return mo.groups ()

def read_file_line(s):
    file = open(s, 'r') 
    Lines = file.readlines() 
    return Lines
def get_loss_in_lines(lines):
    loss = []
    for line in lines: 
        params = parse(line.strip())
        if params != None :
            loss.append(float(params[7]))
    return loss

def get_ave_loss_rate_from_types(types):
    if types == 1:
        prefix = "iperf_log/iperf_server_rr_"
    elif types == 2:
        prefix = "iperf_log/iperf_server_sp_"
    else :
        prefix = "iperf_log/iperf_server_"

    file_loss_list = []

    for i in range(2,18):
        lines = read_file_line(prefix + str(i) + ".txt")
        loss_list = get_loss_in_lines(lines)
        file_loss_list.append(loss_list)

    ave_loss_rate_sum = np.array([0.0] * 60)
    ave_loss_cnt = np.array([1] * 60)
    for i in range(0,16):
        length = len(file_loss_list[i])-1
        ave_loss_rate_sum[i:i+length] += np.array(file_loss_list[i][0:length])
        ave_loss_cnt[i:i+length] += np.array([1] * length)

    ave_loss_rate = ave_loss_rate_sum / ave_loss_cnt
    ave_loss_rate = ave_loss_rate[ave_loss_rate != 0.0]
    return ave_loss_rate

print 'Please input output file name:'
output_file = sys.stdin.readline().strip('\n')


# for i in range(0,16):
#     start_time = 1.5 * i
#     xaxis = [j * 1.0 + start_time for j in range( 0, len(file_loss_list[i])-1 ) ]
#     plt.plot(xaxis, file_loss_list[i][:len(file_loss_list[i])-1], label = str(i))
ave_loss_rate_lb = get_ave_loss_rate_from_types(0)
ave_loss_rate_rr = get_ave_loss_rate_from_types(1)
ave_loss_rate_sp = get_ave_loss_rate_from_types(2)

plt.plot(ave_loss_rate_lb, label = "load balancer")
plt.plot(ave_loss_rate_rr, label = "round robin")
plt.plot(ave_loss_rate_sp, label = "shortest path")

plt.ylim((0.0,100.0))
plt.yticks(np.arange(0.0, 100.0, 5.0))
         
plt.xlabel('time(Sec)')
plt.ylabel('loss rate(%)')

plt.legend()
plt.savefig(output_file)
