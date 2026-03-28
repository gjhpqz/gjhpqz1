#!/bin/bash
# ============================================================
# Linux Performance Testing Script
# 整合自 linux_tools 目录下所有 md 文件的测试工具
# 严格按照 md 文档中的方法执行
# ============================================================

OUTPUT_FILE="$(dirname "$0")/test_results.txt"
CPU_COUNT=$(nproc)
MEM_SIZE=$(free -m | grep Mem | awk '{print int($2)}')

# 初始化输出文件
init_output() {
    echo "============================================================" > "$OUTPUT_FILE"
    echo "Linux Performance Test Results" >> "$OUTPUT_FILE"
    echo "Test Time: $(date)" >> "$OUTPUT_FILE"
    echo "Hostname: $(hostname)" >> "$OUTPUT_FILE"
    echo "Kernel: $(uname -r)" >> "$OUTPUT_FILE"
    echo "CPU Cores: $CPU_COUNT" >> "$OUTPUT_FILE"
    echo "Memory: $(free -h | grep Mem | awk '{print $2}')" >> "$OUTPUT_FILE"
    echo "============================================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

print_separator() {
    echo "" >> "$OUTPUT_FILE"
    echo "------------------------------------------------------------" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

print_test_title() {
    local title="$1"
    echo "" >> "$OUTPUT_FILE"
    echo "============================================================" >> "$OUTPUT_FILE"
    echo "Test: $title" >> "$OUTPUT_FILE"
    echo "============================================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "[Running] $title"
}

check_command() {
    command -v "$1" &> /dev/null
}

# ============================================================
# 1. CPU性能测试 - sysbench_cpu_tool.md
# ============================================================
run_sysbench_cpu() {
    print_test_title "sysbench CPU - CPU性能测试"
    
    if [ -f "/data/sysbench-1.0.17/src/sysbench" ]; then
        # 按照md文档方法运行
        /data/sysbench-1.0.17/src/sysbench --threads=$CPU_COUNT cpu --time=300 run 2>&1 | tee -a "$OUTPUT_FILE"
    elif check_command sysbench; then
        sysbench --threads=$CPU_COUNT cpu --time=300 run 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "sysbench not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y gcc gcc-c++ automake make libtool mariadb-devel sysstat" >> "$OUTPUT_FILE"
        echo "fileserver -d sysbench-1.0.17.zip /data/sysbench-1.0.17.zip" >> "$OUTPUT_FILE"
        echo "cd /data && unzip sysbench-1.0.17.zip && cd ./sysbench-1.0.17" >> "$OUTPUT_FILE"
        echo "./autogen.sh && ./configure --with-mysql --with-mysql-includes=/usr/include/mysql --with-mysql-libs=/usr/lib64/mysql" >> "$OUTPUT_FILE"
        echo "make && make install" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 2. CPU性能测试 - sysbench_mem_tool.md
# ============================================================
run_sysbench_mem() {
    print_test_title "sysbench Memory - 内存性能测试"
    
    if [ -f "/data/sysbench-1.0.17/src/sysbench" ]; then
        /data/sysbench-1.0.17/src/sysbench --threads=$CPU_COUNT memory --time=300 run 2>&1 | tee -a "$OUTPUT_FILE"
    elif check_command sysbench; then
        sysbench --threads=$CPU_COUNT memory --time=300 run 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "sysbench not installed." >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 3. CPU性能测试 - super_pi_tool.md
# ============================================================
run_super_pi() {
    print_test_title "Super PI - 单线程浮点计算测试"
    
    # 按照md文档方法
    if check_command bc; then
        echo "Calculating PI to 5000 digits..." >> "$OUTPUT_FILE"
        { time echo "scale=5000;4*a(1)" | bc -l -q >/dev/null; } 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "bc not installed. Install: yum install -y bc" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 4. CPU性能测试 - stress_ng.md
# ============================================================
run_stress_ng() {
    print_test_title "Stress-NG - CPU压力测试"
    
    if check_command stress-ng; then
        # 按照md文档方法 - 测试CPU性能
        echo "Running stress-ng CPU test..." >> "$OUTPUT_FILE"
        stress-ng --cpu $CPU_COUNT --timeout 60s --times --metrics 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running stress-ng urandom test..." >> "$OUTPUT_FILE"
        stress-ng --urandom $CPU_COUNT --timeout 60s --times --metrics 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running stress-ng zlib test..." >> "$OUTPUT_FILE"
        stress-ng --zlib $CPU_COUNT --timeout 60s --times --metrics 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running stress-ng crypt test..." >> "$OUTPUT_FILE"
        stress-ng --crypt $CPU_COUNT --timeout 60s --times --metrics 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "stress-ng not installed. Install: yum install -y stress-ng" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 5. CPU性能测试 - compress_tool.md
# ============================================================
run_compress() {
    print_test_title "7za Bench - 压缩/解压性能测试"
    
    if check_command 7za; then
        # 按照md文档方法: 7za b -mmt={t} -md={d}
        # -mmt 设置线程数，-md 设置上层字典大小为27
        echo "Running 7za benchmark with $CPU_COUNT threads..." >> "$OUTPUT_FILE"
        7za b -mmt=$CPU_COUNT -md=27 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running 7za benchmark with 1 thread..." >> "$OUTPUT_FILE"
        7za b -mmt=1 -md=27 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "p7zip not installed. Install: yum install -y p7zip" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 6. CPU性能测试 - unixbench_tool.md
# ============================================================
run_unixbench() {
    print_test_title "UnixBench - CPU性能综合测试"
    
    if [ -f "/data/unixbench/Run" ]; then
        # 按照md文档方法运行
        cd /data/unixbench
        echo "Running UnixBench with $CPU_COUNT threads..." >> "$OUTPUT_FILE"
        /data/unixbench/Run -c $CPU_COUNT 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "UnixBench not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y perl-Time-HiRes gcc make perl" >> "$OUTPUT_FILE"
        echo "mkdir -p /data/unixbench" >> "$OUTPUT_FILE"
        echo "fileserver -d UnixBench_5.1.3a.tar /data/unixbench/UnixBench_5.1.3a.tar" >> "$OUTPUT_FILE"
        echo "cd /data/unixbench && tar -xvf UnixBench_5.1.3a.tar" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 7. 内存性能测试 - stream_tool.md
# ============================================================
run_stream() {
    print_test_title "STREAM - 内存带宽测试"
    
    if [ -f "/data/memory_tools/stream/stream" ]; then
        # 按照md文档方法
        # thread默认为1，一般测试两组，一组单线程(thread=1), 一组整机(thread=cpu_count)
        echo "Running STREAM with 1 thread..." >> "$OUTPUT_FILE"
        export OMP_NUM_THREADS=1
        export GOMP_CPU_AFFINITY=0
        /data/memory_tools/stream/stream 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running STREAM with $CPU_COUNT threads..." >> "$OUTPUT_FILE"
        export OMP_NUM_THREADS=$CPU_COUNT
        export GOMP_CPU_AFFINITY=$(seq -s, 0 $((CPU_COUNT-1)))
        /data/memory_tools/stream/stream 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "STREAM not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y gcc numactl" >> "$OUTPUT_FILE"
        echo "fileserver -d memory_tools.tar.gz /data/memory_tools.tar.gz" >> "$OUTPUT_FILE"
        echo "rm -rf /data/memory_tools && mkdir -p /data/memory_tools" >> "$OUTPUT_FILE"
        echo "tar -zxvf /data/memory_tools.tar.gz -C /data" >> "$OUTPUT_FILE"
        echo "cd /data/memory_tools/stream" >> "$OUTPUT_FILE"
        echo "gcc -mcmodel=large -fopenmp -D_OPENMP -DSTREAM_ARRAY_SIZE=1073741824 stream.c -o stream -O3" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 8. 内存性能测试 - lmbench_tool.md
# ============================================================
run_lmbench() {
    print_test_title "LMbench - 内存延迟测试"
    
    if [ -f "/data/lmbench3/bin/x86_64-linux-gnu/lat_mem_rd" ]; then
        # 按照md文档方法
        echo "Running lmbench lat_mem_rd (same numa, hardware prefetch on)..." >> "$OUTPUT_FILE"
        cd /data/lmbench3/bin/x86_64-linux-gnu
        numactl --cpunodebind=0 --membind=0 ./lat_mem_rd 2000 128 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running lmbench lat_mem_rd (same numa, hardware prefetch off)..." >> "$OUTPUT_FILE"
        numactl --cpunodebind=0 --membind=0 ./lat_mem_rd -t 2000 128 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "lmbench not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "fileserver -d lmbench3.tar.gz /data/lmbench3.tar.gz" >> "$OUTPUT_FILE"
        echo "tar -xvf /data/lmbench3.tar.gz -C /data" >> "$OUTPUT_FILE"
        echo "yum install -y gcc libtirpc libtirpc-devel numactl" >> "$OUTPUT_FILE"
        echo "chmod -R +x /data/lmbench3" >> "$OUTPUT_FILE"
        echo "cd /data/lmbench3 && mkdir SCCS && touch ./SCCS/s.ChangeSet && make" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 9. 内存性能测试 - mlc_tool.md
# ============================================================
run_mlc() {
    print_test_title "Intel MLC - 内存延迟检查器"
    
    if [ -f "/root/mlc/mlc" ]; then
        # 按照md文档方法运行所有模型
        echo "Running MLC bandwidth_matrix..." >> "$OUTPUT_FILE"
        /root/mlc/mlc --bandwidth_matrix 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running MLC latency_matrix..." >> "$OUTPUT_FILE"
        /root/mlc/mlc --latency_matrix 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running MLC peak_injection_bandwidth..." >> "$OUTPUT_FILE"
        /root/mlc/mlc --peak_injection_bandwidth 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running MLC idle_latency..." >> "$OUTPUT_FILE"
        /root/mlc/mlc --idle_latency 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running MLC loaded_latency..." >> "$OUTPUT_FILE"
        /root/mlc/mlc --loaded_latency 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "MLC not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y libaio-devel gcc" >> "$OUTPUT_FILE"
        echo "mkdir -p /root/mlc" >> "$OUTPUT_FILE"
        echo "fileserver -d mlc_v3.9a.tgz ~/mlc/mlc_v3.9a.tgz" >> "$OUTPUT_FILE"
        echo "cd /root/mlc && tar -xzvf mlc_v3.9a.tgz" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 10. 磁盘IO性能测试 - fio_tool.md
# ============================================================
run_fio() {
    print_test_title "FIO - 磁盘IO性能测试"
    
    if check_command fio || [ -f "/data/fio-fio-3.14/fio" ]; then
        FIO_CMD="fio"
        [ -f "/data/fio-fio-3.14/fio" ] && FIO_CMD="/data/fio-fio-3.14/fio"
        
        local test_dir="/tmp/fio_test_$$"
        mkdir -p "$test_dir"
        
        # 按照md文档方法 - 128KB顺序读
        echo "Running FIO 128KB sequential read (iodepth=128)..." >> "$OUTPUT_FILE"
        $FIO_CMD --direct=1 --end_fsync=1 --refill_buffers --norandommap --randrepeat=0 --group_reporting --name=fio-test --offset=0G --time_based --runtime=60 --ioengine=libaio --rw=read --bs=128kb --iodepth=128 --numjobs=1 --filename="$test_dir/testfile" --output-format=json 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running FIO 128KB sequential write (iodepth=128)..." >> "$OUTPUT_FILE"
        $FIO_CMD --direct=1 --end_fsync=1 --refill_buffers --norandommap --randrepeat=0 --group_reporting --name=fio-test --offset=0G --time_based --runtime=60 --ioengine=libaio --rw=write --bs=128kb --iodepth=128 --numjobs=1 --filename="$test_dir/testfile" --output-format=json 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running FIO 4KB random read (iodepth=128)..." >> "$OUTPUT_FILE"
        $FIO_CMD --direct=1 --end_fsync=1 --refill_buffers --norandommap --randrepeat=0 --group_reporting --name=fio-test --offset=0G --time_based --runtime=60 --ioengine=libaio --rw=randread --bs=4kb --iodepth=128 --numjobs=8 --filename="$test_dir/testfile" --output-format=json 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running FIO 4KB random write (iodepth=128)..." >> "$OUTPUT_FILE"
        $FIO_CMD --direct=1 --end_fsync=1 --refill_buffers --norandommap --randrepeat=0 --group_reporting --name=fio-test --offset=0G --time_based --runtime=60 --ioengine=libaio --rw=randwrite --bs=4kb --iodepth=128 --numjobs=8 --filename="$test_dir/testfile" --output-format=json 2>&1 | tee -a "$OUTPUT_FILE"
        
        rm -rf "$test_dir"
    else
        echo "fio not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y libaio-devel gcc" >> "$OUTPUT_FILE"
        echo "fileserver -d fio-fio-3.14.tar.gz /data/fio-fio-3.14.tar.gz" >> "$OUTPUT_FILE"
        echo "cd /data && tar -xf fio-fio-3.14.tar.gz" >> "$OUTPUT_FILE"
        echo "cd fio-fio-3.14 && ./configure && make && make install" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 11. 磁盘IO性能测试 - iozone_tool.md
# ============================================================
run_iozone() {
    print_test_title "IOZone - 文件系统性能测试"
    
    if [ -f "/data/iozone3_493/src/current/iozone" ]; then
        # 按照md文档方法
        # -s 设置为机器内存的一半
        local test_size=$((MEM_SIZE / 2))
        echo "Running IOZone with ${test_size}M test file..." >> "$OUTPUT_FILE"
        cd /data/iozone3_493/src/current
        ./iozone -s ${test_size}m -r 16m -i 0 -i 1 -f /data/iozone.data -Rb /data/iozone.xls 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "IOZone not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "fileserver -d iozone3_493.tgz /data/iozone3_493.tgz" >> "$OUTPUT_FILE"
        echo "cd /data && tar -xvf iozone3_493.tgz" >> "$OUTPUT_FILE"
        echo "cd /data/iozone3_493/src/current && make linux-AMD64" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 12. 网络性能测试 - iperf3_tool.md
# ============================================================
run_iperf3() {
    print_test_title "iperf3 - 网络性能测试"
    
    if check_command iperf3; then
        # 按照md文档方法
        echo "iperf3 installed. Usage from md:" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "TCP上行测试:" >> "$OUTPUT_FILE"
        echo "  server端: iperf3 -s -i 1" >> "$OUTPUT_FILE"
        echo "  client端: iperf3 -c {server_ip} -i 1 -P {P} -b {b}M -t 60" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "TCP下行测试:" >> "$OUTPUT_FILE"
        echo "  server端: iperf3 -s -i 1" >> "$OUTPUT_FILE"
        echo "  client端: iperf3 -c {server_ip} -i 1 -P {P} -b {b}M -t 60 -R" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "UDP测试:" >> "$OUTPUT_FILE"
        echo "  server端: iperf3 -s -i 1" >> "$OUTPUT_FILE"
        echo "  client端: iperf3 -c {server_ip} -u -i 1 -P {P} -b {b}M -t 60" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "P: 要运行的并行客户端流的数量，一般等于网卡队列数" >> "$OUTPUT_FILE"
        echo "b: 目标带宽(Mbit/sec)" >> "$OUTPUT_FILE"
    else
        echo "iperf3 not installed. Install: yum install -y iperf3" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 13. 网络性能测试 - iperf2_tool.md
# ============================================================
run_iperf2() {
    print_test_title "iperf2 - 网络性能测试"
    
    if check_command iperf; then
        # 按照md文档方法
        echo "iperf2 installed. Usage from md:" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "TCP测试 (单工):" >> "$OUTPUT_FILE"
        echo "  server端: iperf -s -i 1" >> "$OUTPUT_FILE"
        echo "  client端: iperf -c {server_ip} -i 1 -P {P} -t 60" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "TCP测试 (双工):" >> "$OUTPUT_FILE"
        echo "  server端: iperf -s -i 1" >> "$OUTPUT_FILE"
        echo "  client端: iperf -c {server_ip} -i 1 -P {P} -t 60 -d" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "UDP测试:" >> "$OUTPUT_FILE"
        echo "  server端: iperf -s -i 1 -u" >> "$OUTPUT_FILE"
        echo "  client端: iperf -c {server_ip} -u -i 1 -P {P} -b {b}M -t 60" >> "$OUTPUT_FILE"
    else
        echo "iperf not installed. Install: yum install -y iperf" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 14. 网络性能测试 - netperf_tool.md
# ============================================================
run_netperf() {
    print_test_title "Netperf - 网络吞吐量测试"
    
    if check_command netperf; then
        # 按照md文档方法
        echo "netperf installed. Usage from md:" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Server端: netserver" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Client端测试命令:" >> "$OUTPUT_FILE"
        echo "  UDP 64:   netperf -t UDP_STREAM -H <server_ip> -l 10000 -- -m 64 -R 1 &" >> "$OUTPUT_FILE"
        echo "  UDP 1400: netperf -t UDP_STREAM -H <server_ip> -l 10000 -- -m 1400 -R 1 &" >> "$OUTPUT_FILE"
        echo "  TCP 1500: netperf -t TCP_STREAM -H <server_ip> -l 10000 -- -m 1500 -R 1 &" >> "$OUTPUT_FILE"
        echo "  TCP RR:   netperf -t TCP_RR -H <server_ip> -l 10000 -- -r 32,128 -R 1 &" >> "$OUTPUT_FILE"
        echo "  UDP RR:   netperf -t UDP_RR -H <server_ip> -l 10000 -- -r 32,128 -R 1 &" >> "$OUTPUT_FILE"
        echo "  TCP CRR:  netperf -t TCP_CRR -H <server_ip> -l 10000 -- -r 32,128 -R 1 &" >> "$OUTPUT_FILE"
    else
        echo "netperf not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y sysstat wget tar automake make gcc" >> "$OUTPUT_FILE"
        echo "wget -O netperf-2.7.0.tar.gz -c https://codeload.github.com/HewlettPackard/netperf/tar.gz/netperf-2.7.0" >> "$OUTPUT_FILE"
        echo "tar zxf netperf-2.7.0.tar.gz && cd netperf-netperf-2.7.0" >> "$OUTPUT_FILE"
        echo "./autogen.sh && ./configure && make && make install" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 15. 网络性能测试 - sockperf_tool.md
# ============================================================
run_sockperf() {
    print_test_title "Sockperf - Socket性能测试"
    
    if check_command sockperf; then
        # 按照md文档方法
        echo "sockperf installed. Usage from md:" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Server端 TCP: sockperf sr --tcp -p 11111" >> "$OUTPUT_FILE"
        echo "Server端 UDP: sockperf sr -p 11111" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Client端 TCP: sockperf ul -i {server_ip} --mps=100000 -t 100 -m 64 --reply-every=50 --tcp --full-log=result.json" >> "$OUTPUT_FILE"
        echo "Client端 UDP: sockperf {test_type} -i {server_ip} -m 64 -t 100" >> "$OUTPUT_FILE"
    else
        echo "sockperf not installed. Install: yum install -y sockperf" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 16. 延迟测试 - cyclictest_tool.md
# ============================================================
run_cyclictest() {
    print_test_title "Cyclictest - 实时延迟测试"
    
    if [ -f "/data/rt-tests-1.3/cyclictest" ]; then
        # 按照md文档方法
        echo "Running cyclictest (duration=180s)..." >> "$OUTPUT_FILE"
        cd /data/rt-tests-1.3
        ./cyclictest -p 90 -m -i 1000 -t -q -D 180 -h 15 -z 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "cyclictest not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y gcc numactl-devel" >> "$OUTPUT_FILE"
        echo "fileserver -d rt-tests-1.3-new.tar.gz rt-tests-1.3-new.tar.gz" >> "$OUTPUT_FILE"
        echo "tar -xvf rt-tests-1.3-new.tar.gz && cd rt-tests-1.3/ && make" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 17. 延迟测试 - hackbench_tool.md
# ============================================================
run_hackbench() {
    print_test_title "Hackbench - 内核调度器测试"
    
    if [ -f "/data/hackbench/hackbench" ]; then
        # 按照md文档方法
        echo "Running hackbench tests..." >> "$OUTPUT_FILE"
        ulimit -n 1024000
        
        echo "Test 1: hackbench 100 thread 1000" >> "$OUTPUT_FILE"
        /data/hackbench/hackbench 100 thread 1000 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Test 2: hackbench 100 process 1000" >> "$OUTPUT_FILE"
        /data/hackbench/hackbench 100 process 1000 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Test 3: hackbench 0.5*cores thread 1000" >> "$OUTPUT_FILE"
        local half_cores=$((CPU_COUNT / 2))
        /data/hackbench/hackbench $half_cores thread 1000 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Test 4: hackbench 1*cores thread 1000" >> "$OUTPUT_FILE"
        /data/hackbench/hackbench $CPU_COUNT thread 1000 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "hackbench not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "fileserver -d hackbench-0422.zip hackbench-0422.zip" >> "$OUTPUT_FILE"
        echo "unzip hackbench-0422.zip && chmod +x /data/hackbench/hackbench" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 18. 延迟测试 - contextswitch_tool.md
# ============================================================
run_contextswitch() {
    print_test_title "Context Switch - 上下文切换测试"
    
    if [ -f "/data/contextswitch-master/cpubench.sh" ]; then
        # 按照md文档方法
        echo "Running context switch benchmark..." >> "$OUTPUT_FILE"
        cd /data/contextswitch-master
        ./cpubench.sh 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "contextswitch not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y unzip gcc" >> "$OUTPUT_FILE"
        echo "fileserver -d contextswitch-master.zip /data/contextswitch-master.zip" >> "$OUTPUT_FILE"
        echo "unzip -oq /data/contextswitch-master.zip -d /data" >> "$OUTPUT_FILE"
        echo "cd /data/contextswitch-master && make" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 19. 延迟测试 - perf_bench_tool.md
# ============================================================
run_perf_bench() {
    print_test_title "Perf Bench - 内核性能测试"
    
    if check_command perf; then
        # 按照md文档方法
        echo "Running perf bench sched all..." >> "$OUTPUT_FILE"
        perf bench sched all 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running perf bench futex all..." >> "$OUTPUT_FILE"
        perf bench futex all 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "perf not installed. Install: yum install -y perf" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 20. 延迟测试 - core_latency_tool.md
# ============================================================
run_core_latency() {
    print_test_title "Core Latency - CPU核心间延迟测试"
    
    if [ -f "/data/core-latency/core-latency" ]; then
        # 按照md文档方法
        echo "Running core-latency benchmark..." >> "$OUTPUT_FILE"
        cd /data/core-latency
        ./core-latency 10000 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "core-latency not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y boost-devel make gcc gcc-c++ numactl-devel" >> "$OUTPUT_FILE"
        echo "pip3 install openpyxl==3.0.3 numpy" >> "$OUTPUT_FILE"
        echo "fileserver -d core-latency-1.0.zip /data/core-latency-1.0.zip" >> "$OUTPUT_FILE"
        echo "cd /data && unzip core-latency-1.0.zip" >> "$OUTPUT_FILE"
        echo "cd /data/core-latency && make" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 21. 数据库测试 - redis_tool.md
# ============================================================
run_redis_benchmark() {
    print_test_title "Redis Benchmark - Redis性能测试"
    
    if check_command redis-benchmark; then
        # 启动redis服务
        if check_command redis-server; then
            # 按照md文档配置redis
            sed -i "s/^bind 127.0.0.1/#bind 127.0.0.1/g" /etc/redis.conf 2>/dev/null
            sed -i "s/^protected-mode yes/protected-mode no/g" /etc/redis.conf 2>/dev/null
            sed -i "s/^save 900 1/#save 900 1/g" /etc/redis.conf 2>/dev/null
            sed -i "s/^save 300 10/#save 300 10/g" /etc/redis.conf 2>/dev/null
            sed -i "s/^save 60 10000/#save 60 10000/g" /etc/redis.conf 2>/dev/null
            
            redis-server --daemonize yes --save "" --appendonly no 2>/dev/null
            sleep 2
            
            # 按照md文档方法运行
            echo "Running redis-benchmark..." >> "$OUTPUT_FILE"
            redis-benchmark -h 127.0.0.1 -n 1000000 -r 100000 -t set,get,incr,hset,sadd -P 64 -d 1024 -c 300 2>&1 | tee -a "$OUTPUT_FILE"
            
            redis-cli shutdown 2>/dev/null
        else
            echo "redis-server not installed." >> "$OUTPUT_FILE"
        fi
    else
        echo "redis-benchmark not installed." >> "$OUTPUT_FILE"
        echo "Install method from md: yum install -y redis" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 22. 加密测试 - openssl_tool.md
# ============================================================
run_openssl() {
    print_test_title "OpenSSL Speed - 加密性能测试"
    
    if [ -f "/usr/local/ssl/bin/openssl" ]; then
        # 按照md文档方法
        export LD_LIBRARY_PATH=/usr/local/ssl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
        echo "Running openssl speed test..." >> "$OUTPUT_FILE"
        /usr/local/ssl/bin/openssl speed 2>&1 | tee -a "$OUTPUT_FILE"
    elif check_command openssl; then
        echo "Running openssl speed test..." >> "$OUTPUT_FILE"
        openssl speed 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "openssl not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y perl-core zlib-devel" >> "$OUTPUT_FILE"
        echo "fileserver -d openssl-1.1.1k.tar.gz /data/openssl-1.1.1k.tar.gz" >> "$OUTPUT_FILE"
        echo "cd /data && tar -zxf openssl-1.1.1k.tar.gz" >> "$OUTPUT_FILE"
        echo "cd openssl-1.1.1k" >> "$OUTPUT_FILE"
        echo "./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib" >> "$OUTPUT_FILE"
        echo "make && make test && make install" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 23. Linpack测试 - linpack_tool.md
# ============================================================
run_linpack() {
    print_test_title "Linpack - SIMD指令测试"
    
    if [ -f "/data/intel/mkl/benchmarks/linpack/runme_xeon64" ]; then
        # 按照md文档方法
        echo "Running Linpack benchmark..." >> "$OUTPUT_FILE"
        export GOMP_CPU_AFFINITY=$(seq -s, 0 $((CPU_COUNT-1)))
        cd /data/intel/mkl/benchmarks/linpack/
        ./runme_xeon64 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "Linpack not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y python2 unzip make" >> "$OUTPUT_FILE"
        echo "fileserver -d intel_linpack.tar /data/intel_linpack.tar" >> "$OUTPUT_FILE"
        echo "cd /data && tar -xvf intel_linpack.tar" >> "$OUTPUT_FILE"
        echo "cd /data/l_mkl_2019.1.144/" >> "$OUTPUT_FILE"
        echo "sh ./install.sh -s silent.cfg" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 24. SpecJBB测试 - specjbb_tool.md
# ============================================================
run_specjbb() {
    print_test_title "SpecJBB - Java服务器性能测试"
    
    if [ -f "/data/SPECjbb2015/run_composite.sh" ]; then
        # 按照md文档方法
        echo "Running SPECjbb2015 (this may take a while)..." >> "$OUTPUT_FILE"
        cd /data/SPECjbb2015
        setsid sh ./run_composite.sh 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "SPECjbb2015 not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "fileserver -d zulu11.41.23-ca-jdk11.0.8-linux.x86_64.rpm /data/zulu11.41.23-ca-jdk11.0.8-linux.x86_64.rpm" >> "$OUTPUT_FILE"
        echo "yum localinstall -y zulu11.41.23-ca-jdk11.0.8-linux.x86_64.rpm" >> "$OUTPUT_FILE"
        echo "yum install -y numactl" >> "$OUTPUT_FILE"
        echo "fileserver -d SPECjbb2015-1.03_0.zip /data/SPECjbb2015-1.03_0.zip" >> "$OUTPUT_FILE"
        echo "unzip -oq /data/SPECjbb2015-1.03_0.zip -d /data" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 25. 文件系统测试 - filebench_tool.md
# ============================================================
run_filebench() {
    print_test_title "Filebench - 文件系统性能测试"
    
    if [ -f "/data/filebench_tool/bin/filebench" ]; then
        # 按照md文档方法
        echo "Running filebench varmail..." >> "$OUTPUT_FILE"
        /data/filebench_tool/bin/filebench -f /data/filebench_tool/share/filebench/workloads/varmail.f 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running filebench webserver..." >> "$OUTPUT_FILE"
        /data/filebench_tool/bin/filebench -f /data/filebench_tool/share/filebench/workloads/webserver.f 2>&1 | tee -a "$OUTPUT_FILE"
        
        echo "" >> "$OUTPUT_FILE"
        echo "Running filebench fileserver..." >> "$OUTPUT_FILE"
        /data/filebench_tool/bin/filebench -f /data/filebench_tool/share/filebench/workloads/fileserver.f 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "filebench not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y gcc flex bison" >> "$OUTPUT_FILE"
        echo "fileserver -d filebench-1.5-alpha3.tar.gz /data/filebench-1.5-alpha3.tar.gz" >> "$OUTPUT_FILE"
        echo "cd /data && tar -xf filebench-1.5-alpha3.tar.gz" >> "$OUTPUT_FILE"
        echo "cd filebench-1.5-alpha3" >> "$OUTPUT_FILE"
        echo "./configure --prefix=/data/filebench_tool && make clean && make && make install" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 26. TCP Ping测试 - tcpping_tool.md
# ============================================================
run_tcpping() {
    print_test_title "TCP Ping - TCP延迟测试"
    
    if [ -f "/data/tcpping.sh" ]; then
        # 按照md文档方法
        echo "TCP Ping usage from md:" >> "$OUTPUT_FILE"
        echo "  预热: ./tcpping.sh -r0.5 -w5.0 -x10 {server_ip}" >> "$OUTPUT_FILE"
        echo "  正式测试: ./tcpping.sh -r0.5 -w5.0 -x2400 {server_ip}" >> "$OUTPUT_FILE"
    else
        echo "tcpping not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "fileserver -d tcpping.sh /data/tcpping.sh" >> "$OUTPUT_FILE"
        echo "yum -y install tcptraceroute psmisc" >> "$OUTPUT_FILE"
        echo "chmod 755 /data/tcpping.sh" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 27. Ping测试 - ping_tool.md
# ============================================================
run_ping() {
    print_test_title "Ping - ICMP延迟测试"
    
    if [ -f "/data/ping/ping" ]; then
        # 按照md文档方法
        echo "Ping usage from md:" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "长连接测试(ping_normal):" >> "$OUTPUT_FILE"
        echo "  /data/ping/ping {server_ip} -DO -i 0.5 -s {size}" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "稳定性测试(ping_flood):" >> "$OUTPUT_FILE"
        echo "  /data/ping/ping {server_ip} -D -f -s {size}" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "size: 1400 | 8000" >> "$OUTPUT_FILE"
    else
        echo "ping tool not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y libcap-devel libidn-devel nettle-devel libidn2-devel" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 28. GEMM测试 - gemm_tool.md
# ============================================================
run_gemm() {
    print_test_title "GEMM - 矩阵运算测试"
    
    if [ -f "/data/blis/testsuite/test_libblis.x" ]; then
        # 按照md文档方法
        echo "Running GEMM benchmark..." >> "$OUTPUT_FILE"
        cd /data/blis/testsuite
        GOMP_CPU_AFFINITY=$(seq -s ' ' 0 $((CPU_COUNT-1))) BLIS_NUM_THREADS=$CPU_COUNT ./test_libblis.x 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "GEMM not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "git clone https://github.com/flame/blis.git" >> "$OUTPUT_FILE"
        echo "cd blis && ./configure --enable-cblas -t openmp auto" >> "$OUTPUT_FILE"
        echo "make -j && cd testsuite/ && make -j" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 29. IPI测试 - ipi_tool.md
# ============================================================
run_ipi() {
    print_test_title "IPI - 处理器间中断测试"
    
    if [ -f "/data/ipitest1.1/ipitest.py" ]; then
        # 按照md文档方法
        echo "Running IPI test..." >> "$OUTPUT_FILE"
        cat /proc/sys/kernel/watchdog_thresh
        echo 60 > /proc/sys/kernel/watchdog_thresh
        cd /data/ipitest1.1
        python3 ipitest.py 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "IPI test not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y gcc psmisc elfutils-libelf-devel" >> "$OUTPUT_FILE"
        echo "yum install -y \"kernel-devel-uname-r == \$(uname -r)\"" >> "$OUTPUT_FILE"
        echo "fileserver -d ipitest1.1.zip ipitest1.1.zip" >> "$OUTPUT_FILE"
        echo "unzip ipitest1.1.zip && cd ipitest1.1 && make" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 30. HRtimer测试 - hrtimer_tool.md
# ============================================================
run_hrtimer() {
    print_test_title "HRtimer - 高分辨率定时器测试"
    
    if [ -f "/data/hrtimer/hrtimer_latency.ko" ]; then
        # 按照md文档方法
        echo "Running hrtimer test..." >> "$OUTPUT_FILE"
        echo 0 > /sys/kernel/debug/tracing/trace
        echo 16 > /sys/kernel/debug/tracing/buffer_size_kb
        sleep 5
        rmmod hrtimer_latency 2>/dev/null
        sleep 5
        insmod /data/hrtimer/hrtimer_latency.ko max_times=18000000 timing_delta=200000
        sleep 3900
        rmmod hrtimer_latency
        sleep 5
        cat /sys/kernel/debug/tracing/trace 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "hrtimer not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "fileserver -d hrtimer.zip /data/hrtimer.zip" >> "$OUTPUT_FILE"
        echo "cd /data && unzip hrtimer.zip && cd hrtimer && make" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 31. Kafka测试 - kafka_single_tool.md
# ============================================================
run_kafka() {
    print_test_title "Kafka - 消息队列性能测试"
    
    if [ -f "/usr/kafka/kafka_2.12-2.3.0/bin/kafka-producer-perf-test.sh" ]; then
        # 按照md文档方法
        echo "Kafka usage from md:" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Start zookeeper:" >> "$OUTPUT_FILE"
        echo "  cd /usr/kafka/kafka_2.12-2.3.0/bin && nohup ./zookeeper-server-start.sh ../config/zookeeper.properties &" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Start kafka:" >> "$OUTPUT_FILE"
        echo "  cd /usr/kafka/kafka_2.12-2.3.0/bin && nohup ./kafka-server-start.sh ../config/server.properties &" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Run producer test:" >> "$OUTPUT_FILE"
        echo "  /usr/kafka/kafka_2.12-2.3.0/bin/kafka-producer-perf-test.sh --topic test --num-records 10000 --record-size 8 --throughput 10000 --producer-props bootstrap.servers=127.0.0.1:9092" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Run consumer test:" >> "$OUTPUT_FILE"
        echo "  /usr/kafka/kafka_2.12-2.3.0/bin/kafka-consumer-perf-test.sh --broker-list 127.0.0.1:9092 --topic test --fetch-size 8 --messages 10000 --threads 1 --timeout 120000" >> "$OUTPUT_FILE"
    else
        echo "Kafka not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y java" >> "$OUTPUT_FILE"
        echo "fileserver -d kafka_2.12-2.3.0.tgz /data/kafka_2.12-2.3.0.tgz" >> "$OUTPUT_FILE"
        echo "mkdir /usr/kafka && mkdir /kafka && mkdir /kafka/logs" >> "$OUTPUT_FILE"
        echo "tar -zvxf /data/kafka_2.12-2.3.0.tgz -C /usr/kafka" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 32. VRay CPU测试 - vray_cpu_tool.md
# ============================================================
run_vray_cpu() {
    print_test_title "VRay CPU - 离线渲染测试"
    
    if [ -f "/data/vraybench_1.0.8_lin_x64" ]; then
        # 按照md文档方法
        echo "Running VRay CPU benchmark..." >> "$OUTPUT_FILE"
        /data/vraybench_1.0.8_lin_x64 -m cpu -q 2>&1 | tee -a "$OUTPUT_FILE"
    else
        echo "VRay benchmark not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y gcc" >> "$OUTPUT_FILE"
        echo "fileserver -d vraybench_1.0.8_lin_x64 /data/vraybench_1.0.8_lin_x64" >> "$OUTPUT_FILE"
        echo "chmod +x /data/vraybench_1.0.8_lin_x64" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 33. FFmpeg CPU测试 - ffmpeg_cpu_tool.md
# ============================================================
run_ffmpeg_cpu() {
    print_test_title "FFmpeg CPU - 视频转码测试"
    
    if [ -f "/data/ffmpeg-git-20200617/ffmpeg-git-20200617-amd64-static/ffmpeg" ]; then
        if [ -f "/data/big_buck_bunny_1080p_h264.mov" ]; then
            # 按照md文档方法
            echo "Running FFmpeg CPU benchmark..." >> "$OUTPUT_FILE"
            cd /data/ffmpeg-git-20200617/ffmpeg-git-20200617-amd64-static
            time ./ffmpeg -y -i /data/big_buck_bunny_1080p_h264.mov -vcodec libx264 output0.264 -vcodec libx264 output1.264 -vcodec libx264 output2.264 2>&1 | tee -a "$OUTPUT_FILE"
            rm -f output*.264
        else
            echo "Test video not found. Need: /data/big_buck_bunny_1080p_h264.mov" >> "$OUTPUT_FILE"
        fi
    else
        echo "FFmpeg not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "fileserver -d big_buck_bunny_1080p_h264.mov /data/big_buck_bunny_1080p_h264.mov" >> "$OUTPUT_FILE"
        echo "fileserver -d ffmpeg-git-20200617-amd64-static.tar.xz /data/ffmpeg-git-20200617-amd64-static.tar.xz" >> "$OUTPUT_FILE"
        echo "cd /data && mkdir -p ffmpeg-git-20200617" >> "$OUTPUT_FILE"
        echo "tar -xvf ffmpeg-git-20200617-amd64-static.tar.xz -C ffmpeg-git-20200617" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 34. uPerf测试 - uperf_tool.md
# ============================================================
run_uperf() {
    print_test_title "uPerf - 网络性能测试"
    
    if [ -f "/data/uperf/uperf" ]; then
        # 按照md文档方法
        echo "uPerf usage from md:" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Server端初始化:" >> "$OUTPUT_FILE"
        echo "  cd /data/uperf && python3 init.py -h {server_ip}" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "运行命令示例:" >> "$OUTPUT_FILE"
        echo "  /data/uperf/uperf -S 172.16.48.28:10001-10001 172.16.48.32:10001-10001 64 -b 1024 -i 0 -t 3600 -P 1" >> "$OUTPUT_FILE"
    else
        echo "uPerf not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "pip3 install -U pip" >> "$OUTPUT_FILE"
        echo "yum install -y unzip gcc make" >> "$OUTPUT_FILE"
        echo "fileserver -d uperf.zip /data/uperf.zip" >> "$OUTPUT_FILE"
        echo "unzip -oq /data/uperf.zip -d /data" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 35. RocksDB测试 - rocksdb_tool.md
# ============================================================
run_rocksdb() {
    print_test_title "RocksDB - 数据库性能测试"
    
    if [ -f "/data/rocksdb-6.11.4/RocksDBPerfTest/InitialTest.sh" ]; then
        # 按照md文档方法
        echo "RocksDB usage from md:" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "cd /data/rocksdb-6.11.4/RocksDBPerfTest" >> "$OUTPUT_FILE"
        echo "./InitialTest.sh" >> "$OUTPUT_FILE"
        echo "./ReadTest.sh" >> "$OUTPUT_FILE"
        echo "./WriteTest.sh" >> "$OUTPUT_FILE"
    else
        echo "RocksDB not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y gcc gcc-c++ cmake" >> "$OUTPUT_FILE"
        echo "fileserver -d rocksdb-6.11.4.tar.gz /data/rocksdb-6.11.4.tar.gz" >> "$OUTPUT_FILE"
        echo "cd /data && tar -zxvf rocksdb-6.11.4.tar.gz && cd rocksdb-6.11.4 && make -j" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 36. SpecCPU测试 - speccpu_tool.md
# ============================================================
run_speccpu() {
    print_test_title "SPEC CPU - CPU密集型测试"
    
    if [ -f "/data/speccpu/bin/runcpu" ]; then
        # 按照md文档方法
        echo "SPEC CPU usage from md:" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "cd /data/speccpu" >> "$OUTPUT_FILE"
        echo "export GOMP_CPU_AFFINITY=$(seq -s, 0 $((CPU_COUNT-1)))" >> "$OUTPUT_FILE"
        echo "ulimit -s unlimited" >> "$OUTPUT_FILE"
        echo "source ./shrc" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Run tests:" >> "$OUTPUT_FILE"
        echo "  runcpu --config=baseline.cfg fprate --copies=$CPU_COUNT" >> "$OUTPUT_FILE"
        echo "  runcpu --config=baseline.cfg fpspeed --threads=$CPU_COUNT" >> "$OUTPUT_FILE"
        echo "  runcpu --config=baseline.cfg intrate --copies=$CPU_COUNT" >> "$OUTPUT_FILE"
        echo "  runcpu --config=baseline.cfg intspeed --threads=$CPU_COUNT" >> "$OUTPUT_FILE"
    else
        echo "SPEC CPU not installed." >> "$OUTPUT_FILE"
        echo "Install method from md:" >> "$OUTPUT_FILE"
        echo "yum install -y gcc gcc-c++ gcc-gfortran libstdc++-devel libnsl" >> "$OUTPUT_FILE"
        echo "mkdir -p /data/speccpu" >> "$OUTPUT_FILE"
        echo "fileserver -d cpu2017-1_1_8.tar.gz /data/speccpu/cpu2017-1_1_8.tar.gz" >> "$OUTPUT_FILE"
        echo "tar -xvf /data/speccpu/cpu2017-1_1_8.tar.gz -C /data/speccpu" >> "$OUTPUT_FILE"
        echo "cd /data/speccpu && ./install.sh -d /data/speccpu -f" >> "$OUTPUT_FILE"
    fi
    print_separator
}

# ============================================================
# 系统信息收集
# ============================================================
collect_system_info() {
    print_test_title "System Information"
    
    echo "=== CPU Info ===" >> "$OUTPUT_FILE"
    lscpu 2>&1 | tee -a "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    echo "=== Memory Info ===" >> "$OUTPUT_FILE"
    free -h 2>&1 | tee -a "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    echo "=== Disk Info ===" >> "$OUTPUT_FILE"
    df -h 2>&1 | tee -a "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    echo "=== Network Info ===" >> "$OUTPUT_FILE"
    ip addr 2>&1 | tee -a "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    echo "=== NUMA Info ===" >> "$OUTPUT_FILE"
    numactl --hardware 2>&1 | tee -a "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    print_separator
}

# ============================================================
# 主程序
# ============================================================
main() {
    echo "============================================================"
    echo "Linux Performance Test Script"
    echo "============================================================"
    echo ""

    # 初始化输出文件
    init_output

    # 收集系统信息
    collect_system_info

    # CPU 性能测试
    echo "=== CPU Performance Tests ==="
    run_sysbench_cpu
    run_super_pi
    run_stress_ng
    run_compress
    run_unixbench

    # 内存性能测试
    echo "=== Memory Performance Tests ==="
    run_sysbench_mem
    run_stream
    run_lmbench
    run_mlc

    # 磁盘 I/O 性能测试
    echo "=== Disk I/O Performance Tests ==="
    run_fio
    run_iozone
    run_filebench

    # 网络性能测试
    echo "=== Network Performance Tests ==="
    run_iperf3
    run_iperf2
    run_netperf
    run_sockperf
    run_uperf
    run_tcpping
    run_ping

    # 系统延迟测试
    echo "=== Latency Tests ==="
    run_cyclictest
    run_hackbench
    run_contextswitch
    run_perf_bench
    run_core_latency
    run_ipi
    run_hrtimer

    # 数据库性能测试
    echo "=== Database Performance Tests ==="
    run_redis_benchmark
    run_rocksdb
    run_kafka

    # 加密性能测试
    echo "=== Encryption Performance Tests ==="
    run_openssl

    # 计算性能测试
    echo "=== Compute Performance Tests ==="
    run_linpack
    run_gemm
    run_speccpu
    run_specjbb
    run_vray_cpu
    run_ffmpeg_cpu

    # 完成
    echo "" >> "$OUTPUT_FILE"
    echo "============================================================" >> "$OUTPUT_FILE"
    echo "Test completed at: $(date)" >> "$OUTPUT_FILE"
    echo "============================================================" >> "$OUTPUT_FILE"

    echo ""
    echo "============================================================"
    echo "All tests completed!"
    echo "Results saved to: $OUTPUT_FILE"
    echo "============================================================"
}

# 运行主程序
main "$@"
