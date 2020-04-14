#! /usr/bin/env python
import matplotlib
matplotlib.use('Agg')
import re
import numpy as np
import matplotlib.pyplot as plt
import sys
import pandas as pd
import six


def render_mpl_table(data, col_width=3.0, row_height=0.625, font_size=14,
                     header_color='#40466e', row_colors=['#f1f1f2', 'w'], edge_color='w',
                     bbox=[0, 0, 1, 1], header_columns=0,
                     ax=None, **kwargs):
    if ax is None:
        size = (np.array(data.shape[::-1]) + np.array([0, 1])) * np.array([col_width, row_height])
        fig, ax = plt.subplots(figsize=size)
        ax.axis('off')

    mpl_table = ax.table(cellText=data.values, bbox=bbox, colLabels=data.columns, **kwargs)

    mpl_table.auto_set_font_size(False)
    mpl_table.set_fontsize(font_size)

    for k, cell in six.iteritems(mpl_table._cells):
        cell.set_edgecolor(edge_color)
        if k[0] == 0 or k[1] < header_columns:
            cell.set_text_props(weight='bold', color='w')
            cell.set_facecolor(header_color)
        else:
            cell.set_facecolor(row_colors[k[0]%len(row_colors) ])
    return ax


def Average(lst): 
    return round(sum(lst) / len(lst), 3)

def parse_ping(s):
    mo = re.match ("rtt min/avg/max/mdev = (\d+\.?\d*)/(\d+\.?\d*)/.*", s)
    if mo: return mo.groups ()

def get_lat_in_lines(lines):
    for line in lines: 
        lat = parse_ping(line.strip())
        if lat != None :
            return float(lat[1])
    return 0.0

def parse(s):
    mo = re.match (".*]\ *(\d+.\d+)-\ *(\d+.\d+) sec\ *(\d+.\d+ M|\d+\.?\d* K)Bytes\ *(\d+.\d+) Mbits/sec\ *(\d+.\d+) ms\ *(\d+)/\ *(\d+) \((\d+\.?\d*)%\)", s)
    if mo: return mo.groups ()

def read_file_line(s):
    file = open(s, 'r') 
    Lines = file.readlines() 
    return Lines

def get_loss_throughput_in_lines(lines):
    loss = []
    throughput = []
    for line in lines: 
        params = parse(line.strip())
        if params != None :
            loss.append(float(params[7]))
            throughput.append(float(params[3]))
    return loss, throughput

def get_ave_info_from_iperf(types):
    if types == 1:
        prefix = "iperf_log/iperf_server_rr_"
    elif types == 2:
        prefix = "iperf_log/iperf_server_sp_"
    elif types == 3:
        prefix = "iperf_log/iperf_server_dp_"
    else :
        prefix = "iperf_log/iperf_server_"

    file_loss_list = []
    file_throughput_list = []

    for i in range(2,18):
        lines = read_file_line(prefix + str(i) + ".txt")
        loss_list, throughput_list = get_loss_throughput_in_lines(lines)
        file_loss_list.append(loss_list)
        file_throughput_list.append(throughput_list)

    ave_loss_rate_sum = np.array([0.0] * 60)
    data_cnt = np.array([1] * 60)
    throughput_sum = np.array([0.0] * 60)
    for i in range(0,16):
        length = len(file_loss_list[i])-1
        ave_loss_rate_sum[i:i+length] += np.array(file_loss_list[i][0:length])
        data_cnt[i:i+length] += np.array([1] * length)
        throughput_sum[i:i+length] += np.array(file_throughput_list[i][0:length])

    ave_loss_rate = ave_loss_rate_sum / data_cnt
    ave_loss_rate = ave_loss_rate[ave_loss_rate != 0.0]
    throughput_sum = throughput_sum[throughput_sum != 0.0]
    return ave_loss_rate, throughput_sum


def get_ave_info_from_ping(types):
    if types == 1:
        prefix = "ping_log/ping_rr_"
    elif types == 2:
        prefix = "ping_log/ping_sp_"
    elif types == 3:
        prefix = "ping_log/ping_dp_"
    else :
        prefix = "ping_log/ping_"

    latency = []
    for i in range(2,18):
        lines = read_file_line(prefix + str(i) + ".txt")
        lat = get_lat_in_lines(lines)
        latency.append(lat)
    return latency

def choose_string(s1, s2):
    if s1 == "":
        return s2
    return s1

output_file = ["loss.png", "throughput.png", "lat.png", "table.png"]
folder = "chart/"
print 'Please input output loss file name(default -> loss.png):'
output_file[0] = folder + choose_string(sys.stdin.readline().strip('\n'), output_file[0])
print 'Please input output throughput file name(default -> throughput.png):'
output_file[1] = folder + choose_string(sys.stdin.readline().strip('\n'), output_file[1])
print 'Please input output latency file name(default -> lat.png):'
output_file[2] = folder + choose_string(sys.stdin.readline().strip('\n'), output_file[2])
print 'Please input output summary file name(default -> table.png):'
output_file[3] = folder + choose_string(sys.stdin.readline().strip('\n'), output_file[3])

# for i in range(0,16):
#     start_time = 1.5 * i
#     xaxis = [j * 1.0 + start_time for j in range( 0, len(file_loss_list[i])-1 ) ]
#     plt.plot(xaxis, file_loss_list[i][:len(file_loss_list[i])-1], label = str(i))
ave_loss_rate_lb, throughput_lb = get_ave_info_from_iperf(0)
ave_loss_rate_rr, throughput_rr = get_ave_info_from_iperf(1)
# ave_loss_rate_sp, throughput_sp = get_ave_info_from_iperf(2)
ave_loss_rate_dp, throughput_dp = get_ave_info_from_iperf(3)

plt.plot(ave_loss_rate_lb, label = "RIRM")
plt.plot(ave_loss_rate_rr, label = "Round-Robin")
# plt.plot(ave_loss_rate_sp, label = "Shortest Path")
plt.plot(ave_loss_rate_dp, label = "Dynamic Path")
plt.ylim((0.0,100.0))
plt.yticks(np.arange(0.0, 100.0, 5.0))
plt.xlabel('time(Sec)')
plt.ylabel('loss rate(%)')
plt.legend()
plt.savefig(output_file[0])
plt.close()

plt.plot(throughput_lb, label = "RIRM")
plt.plot(throughput_rr, label = "Round-Robin")
# plt.plot(throughput_sp, label = "Shortest Path")
plt.plot(throughput_dp, label = "Dynamic Path")
plt.ylim((0.0,1000.0))
plt.yticks(np.arange(0.0, 1000.0, 50.0))
plt.xlabel('time(Sec)')
plt.ylabel('throughput(Mbps)')
plt.legend()
plt.savefig(output_file[1])
plt.close()

lat_lb = get_ave_info_from_ping(0)
lat_rr = get_ave_info_from_ping(1)
# lat_sp = get_ave_info_from_ping(2)
lat_dp = get_ave_info_from_ping(3)

width = 0.3
x1 = range(1,17)

plt.bar([i-width for i in x1], lat_lb, width=width,label = "RIRM")
plt.bar([i for i in x1], lat_rr, width=width,label = "Round-Robin")
plt.bar([i+width for i in x1], lat_dp, width=width,label = "Dynamic Path")
# plt.bar([i-width/2*3 for i in x1], lat_lb, width=width,label = "RIRM")
# plt.bar([i-width/2 for i in x1], lat_rr, width=width,label = "Round-Robin")
# plt.bar([i+width/2 for i in x1], lat_sp, width=width,label = "Shortest Path")
# plt.bar([i+width/2*3 for i in x1], lat_dp, width=width,label = "Dynamic Path")
plt.ylim((0.0, 900.0))
plt.yticks(np.arange(0.0, 900.0, 50.0))
plt.xticks(x1)
plt.xlabel('Session Id')
plt.ylabel('latency(ms)')

plt.gcf().set_size_inches(10,4.8)
plt.legend()
plt.savefig(output_file[2])
plt.close()

# print "loss:", Average(ave_loss_rate_lb), Average(ave_loss_rate_rr), Average(ave_loss_rate_sp)
# print "throughput:", Average(throughput_lb), Average(throughput_rr), Average(throughput_sp)
# print "latency:", Average(lat_lb), Average(lat_rr), Average(lat_sp)
ave_loss = ["Loss(%)",Average(ave_loss_rate_lb), Average(ave_loss_rate_rr), Average(ave_loss_rate_dp)]
ave_throughput = ["Throughput(Mbps)",Average(throughput_lb), Average(throughput_rr), Average(throughput_dp)]
ave_lat = ["Latency(ms)",Average(lat_lb), Average(lat_rr), Average(lat_dp)]
df=pd.DataFrame(np.array([ave_loss, ave_throughput, ave_lat]),
                columns= ["","RIRM", "Round-Robin", "Dynamic Path"])

render_mpl_table(df, header_columns=1, col_width=3.0)

plt.savefig(output_file[3])
plt.close()