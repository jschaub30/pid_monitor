(function() {
    "use strict";
    var xlabel,
        hostname,
        run_id,
        time0 = -1,
        header_lines,
        data_dir,
        cumsum_flag = false,
        config,
        monitor_idx = 1,
        //http://colorbrewer2.org/
        chart_colors = ['rgb(228,26,28)', 'rgb(55,126,184)', 'rgb(77,175,74)',
            'rgb(152,78,163)', 'rgb(255,127,0)', 'rgb(141,211,199)'
        ],
        parse_summary_line = function(line) {
            return {
                x: line.run_id,
                //x: line.run_id.split('=')[1].split('.')[0], //threads
                y: line.elapsed_time_sec
            };
        },
        parse_dstat_line = function(line, linenum, factor) {
            var day,
                month,
                time,
                arr,
                time_ms,
                err_str,
                index;

            try {
                day = line.time.split('-')[0];
                month = line.time.split('-')[1].split(' ')[0];
                time = line.time.split(' ')[1].split(':');
                arr = [];
                //time_str = "2015-" + month + '-' + day + ' ' + time
                time_ms = new Date("2015", month, day, time[0], time[1], time[2]);
                //console.log(time_str);
                //time_ms = Date.parse(time_str);
                // console.log(time_ms);
                if (time0 === -1) {
                    time0 = time_ms;
                }
                // console.log((time_ms - time0) / 1000);
                arr.push((time_ms - time0) / 1000);

                for (index = 3; index < arguments.length; index += 1) {
                    arr.push(factor * line[arguments[index]]);
                }
            } catch (err) {
                err_str = "Problem reading CSV file near line ";
                err_str += (linenum + header_lines) + '<br>';
                err_str += JSON.stringify(line) + "<br>" + err.message;
                $("#id_error").html(err_str);
            }
            return arr;
        },
        csv_chart = function(data, id, title, labels, ylabel) {
            //console.log(data);
            var chart = new Dygraph(
                document.getElementById(id),
                data, {
                    labels: labels,
                    colors: chart_colors,
                    xlabel: "Elapsed time [ sec ]",
                    ylabel: ylabel,
                    strokeWidth: 2,
                    legend: 'always',
                    labelsDivWidth: 500,
                    title: title
                }
            );
            return chart;
        },
        csv_chart2 = function(data, monitor_idx, title) {
            var id_str = "id_monitor" + monitor_idx.toString();
            $(id_str).show();
            //console.log(data);
            var chart = new Dygraph(
                document.getElementById(id_str),
                data, {
                    // labels: labels,
                    colors: chart_colors,
                    xlabel: "Elapsed time [ sec ]",
                    // ylabel: ylabel,
                    strokeWidth: 2,
                    legend: 'always',
                    connectSeparatedPoints: true,
                    labelsDivWidth: 500,
                    title: title
                }
            );
            return chart;
        },
        calc_cumsum = function(data) {
            var new_array = [],
                dt;
            for (var i = 0; i < data.length; i++) {
                new_array.push(data[i].slice(0));
            }
            for (i = 1; i < new_array.length; i++) {
                dt = new_array[i][0] - new_array[i - 1][0];
                for (var j = 1; j < new_array[0].length; j++) {
                    new_array[i][j] = new_array[i - 1][j] + dt * new_array[i][j];
                }
            }
            return new_array;
        },
        create_dstat_charts = function(data) {
            var index = 0,
                flag = true,
                lines = data.split('\n'),
                labels,
                header,
                body,
                csv_data,
                cpu_data,
                mem_data,
                io_data,
                net_data,
                sys_data,
                proc_data,
                pag_data;

            while (flag) {
                // Skip first few lines of dstat file
                if (lines[index].indexOf("system") !== -1) {
                    flag = false;
                }
                index += 1;
            }
            labels = lines[index];
            header = lines.slice(0, index - 2);
            body = lines.slice(index, lines.length);

            header = header.join(['<br>']);
            //$("#id_header").html(header);
            header_lines = index; // Used in error message in parse_dstat_line()

            time0 = -1;
            csv_data = $.csv.toObjects(body.join(['\n']));
            // console.log(csv_data);
            cpu_data = csv_data.map(
                function(x, index) {
                    return parse_dstat_line(x, index, 1, "usr", "sys", "idl", "wai", "hiq", "siq");
                }
            );
            var factor_g = 1 / 1024 / 1024 / 1024,
                factor_m = 1 / 1024 / 1024;
            mem_data = csv_data.map(
                function(x, index) {
                    return parse_dstat_line(x, index, factor_g, "used", "buff", "cach", "free");
                }
            );
            io_data = csv_data.map(
                function(x, index) {
                    return parse_dstat_line(x, index, factor_g, "read", "writ");
                }
            );
            var io_sum_data = calc_cumsum(io_data);

            net_data = csv_data.map(
                function(x, index) {
                    return parse_dstat_line(x, index, factor_g, "recv", "send");
                }
            );
            var net_sum_data = calc_cumsum(net_data);
            sys_data = csv_data.map(
                function(x, index) {
                    return parse_dstat_line(x, index, 1, "int", "csw");
                }
            );
            proc_data = csv_data.map(
                function(x, index) {
                    return parse_dstat_line(x, index, 1, "run", "blk", "new");
                }
            );
            pag_data = csv_data.map(
                function(x, index) {
                    return parse_dstat_line(x, index, 1, "in", "out");
                }
            );

            csv_chart(cpu_data, "id_cpu", "CPU", ["time", "user", "system",
                "idle", "wait", "hiq", "siq"
            ], "Usage [ % ]");
            csv_chart(mem_data, "id_mem", "Memory", ["time", "used", "buff",
                "cache", "free"
            ], "Usage [ GB ]");
            if (cumsum_flag) {
                csv_chart(io_sum_data, "id_io", "&#x222b; IO", ["time", "read",
                    "write"
                ], "Usage [ GB ]");
            } else {
                csv_chart(io_data, "id_io", "IO", ["time", "read", "write"],
                    "Usage [ GB/s ]");
            }

            if (cumsum_flag) {
                csv_chart(net_sum_data, "id_net", "&#x222b; Network", ["time", "recv", "send"], "Usage [ GB ]");
            } else {
                csv_chart(net_data, "id_net", "Network", ["time", "recv", "send"],
                    "Usage [ GB/s ]");
            }

            csv_chart(sys_data, "id_sys", "System", ["time", "interrupts", "context switches"], "");
            csv_chart(proc_data, "id_proc", "Processes", ["time", "run", "blk", "new"], "");
            //csv_chart(pag_data, "id_pag", "Paging", ["time", "in", "out"], "");
            $('#id_progress').hide();
        },
        load_dstat_csv = function() {
            // Read dstat data based on current value of 'run_id'
            // and 'hostname'
            var url = data_dir + '/' + run_id + '_' + hostname + '_dstat.csv';
            $("#id_data_dir").attr("href", data_dir + "/all_files.html");
            // console.log(url);
            //Read csv data
            $.ajax({
                type: "GET",
                url: url,
                dataType: "text",
                success: create_dstat_charts,
                error: function(request, status, error) {
                    console.log(status);
                    console.log(error);
                }
            });
        },
        load_csv = function(extension, monitor_idx, title) {
            var url = data_dir + '/' + run_id + '_' + hostname + extension;
            // console.log(url);
            $.ajax({
                type: "GET",
                url: url,
                dataType: "text",
                success: function(data) {
                    csv_chart2(data, monitor_idx, title)
                },
                error: function(request, status, error) {
                    console.log(status);
                    console.log(error);
                }
            });
        },
        create_host_button = function(index, id) {
            var button_id = "cluster_button" + String(index),
                button = $('<button></button>', {
                    id: button_id,
                    text: id
                }).appendTo('#cluster_buttons').addClass('button');

            if (index === 0) {
                button.addClass('active');
            }
            $("#" + button_id).on('click', function() {
                var $this = $(this);
                $this.addClass('active');
                $this.siblings('button').removeClass('active');
                hostname = id;
                setTimeout(function() {
                    load_all_data();
                }, 500);
            });
        },
        create_snapshot_link = function(hostname) {
            var link = $('<a></a>', {
                href: hostname + '.html',
                text: hostname
            }).appendTo('#id_snapshot').addClass('snapshot');
        },
        create_run_button = function(index, id) {
            var button_id = "button" + String(index),
                button = $('<button></button>', {
                    id: button_id,
                    text: id
                }).appendTo('#run_id_buttons').addClass('button');

            if (index === 0) {
                button.addClass('active');
            }
            $("#" + button_id).on('click', function() {
                var $this = $(this);
                $this.addClass('active');
                $this.siblings('button').removeClass('active');
                run_id = id;
                setTimeout(function() {
                    load_all_data();
                }, 500);
            });
        },
        create_sum_button = function() {
            var button_id = "sum_button",
                button = $('<button></button>', {
                    id: button_id,
                    text: "Integrate IO and network"
                }).appendTo('#sum_buttons').addClass('button');

            $("#" + button_id).on('click', function() {
                var $this = $(this);
                $this.toggleClass('active');
                cumsum_flag = !cumsum_flag;
                setTimeout(function() {
                    load_all_data();
                    load_monitor_data();
                }, 500);
            });
        },
        create_all_buttons = function(hostnames, run_ids) {
            var index;
            for (index = 0; index < hostnames.length; ++index) {
                create_host_button(index, hostnames[index]);
                create_snapshot_link(hostnames[index]);
            }
            for (index = 0; index < run_ids.length; ++index) {
                create_run_button(index, run_ids[index]);
            }
            create_sum_button();
        },
        summary_chart = function(data, id) {
            //console.log(id);
            //console.log(data);

            c3.generate({
                bindto: id,
                // size: {
                // height: 600
                // },
                data: {
                    json: data,
                    keys: {
                        x: 'x',
                        value: ['y']
                    },
                    names: {
                        y: 'Elapsed time [ sec ]'
                    },
                    type: "bar"
                },
                grid: {
                    x: {
                        show: true
                    },
                    y: {
                        show: true
                    }
                },
                point: {
                    r: 5
                },
                axis: {
                    x: {
                        type: 'category',
                        // min: 0,
                        //max: 100,
                        label: {
                            text: xlabel,
                            position: 'outer-right'
                        }
                    },
                    y: {
                        min: 0,
                        // max: 100,
                        label: {
                            text: 'Elapsed execution time [ seconds ]',
                            position: 'outer-middle'
                        }
                    },
                }
            });
        },
        load_summary = function() {
            //Read summary CSV data and create summary chart
            $.ajax({
                type: "GET",
                url: "summary.csv",
                dataType: "text",
                success: function(data) {
                    var csv_data = $.csv.toObjects(data);
                    // console.log(csv_data);
                    csv_data = csv_data.map(parse_summary_line);
                    // console.log(csv_data);
                    setTimeout(function() {
                        summary_chart(csv_data, "#summary_chart");
                    });
                },
                error: function(request, status, error) {
                    console.log(error);
                }
            });
        },
        load_all_data = function() {
            if (config.monitors.indexOf("dstat") > -1) {
                load_dstat_csv();
            }
            monitor_idx = 1;
            if (config.monitors.indexOf("membw") > -1) {
                load_csv('_ocount.memory_bw.csv', monitor_idx,
                    'Cache/Memory Bandwidth [ GB/s ]');
                monitor_idx += 1;
            }
            if (config.monitors.indexOf("gpu") > -1) {
                load_csv('_gpu.csv', monitor_idx, 'Average GPU Utilization [ % ]');
                monitor_idx += 1;
                load_csv('_gpu.pwr.csv', monitor_idx, 'Average GPU Power [ W ]');
                monitor_idx += 1;
            }
            if (config.monitors.indexOf("gpu_detail") > -1) {
                load_csv('_gpu.gpu.csv', monitor_idx, 'Detail GPU Utilization [ % ]');
                monitor_idx += 1;
                load_csv('_gpu.mem.csv', monitor_idx, 'Detail GPU Memory Utilization [ % ]');
                monitor_idx += 1;
            }
            if (config.monitors.indexOf("amester") > -1) {
                load_csv('_amester.csv', monitor_idx,
                    'AMESTER memory bandwidth [ GB/s ]');
                monitor_idx += 1;
            }
            if (config.monitors.indexOf("cpu_detail") > -1) {
                load_cpu_detail();
            }
        },
        load_cpu_detail = function() {
            $.ajax({
                type: "GET",
                url: data_dir + '/' + run_id + '_' + hostname + '_cpu_detail.csv.js',
                dataType: "json",
                success: function(data) {
                    $("#id_cpu_heatmap").show();
                    var ctx = document.getElementById("id_cpu_detail").getContext("2d");
                    var sampleChart = new Chart(ctx).HeatMap(data, {
                        responsive: true,
                        maintainAspectRatio: false,
                        rounded: false,
                        paddingScale: 0.0,
                        showLabels: false,
                        showScale: false,
                        tooltipTemplate: "t: <%= xLabel %> | cpu: <%= yLabel %> | value: <%= value %>%",
                        colorInterpolation: 'gradient',
                        colors: ['rgb(220,220,220)', 'red']
                    });
                    $('#id_cpu_y0').text('cpu' + data.datasets[0].label);
                    $('#id_cpu_y1').text('cpu' + data.datasets[data.datasets.length - 1].label);
                    $('#id_cpu_x1').text(data.labels[data.labels.length - 1] + 's');
                    $('#id_cpu_x0').text(data.labels[0] + 's');
                },
                error: function(request, status, error) {
                    console.log(error);
                }
            });
        },
        update_page = function(config, showTest) {
            // console.log(data);
            xlabel = config.xlabel;
            data_dir = '../data/raw';
            if (config.hasOwnProperty('config_dir')) {
                config_dir = config.config_dir;
            }

            $('#id_workload').text(config.description);
            $('#id_title').text(config.workload);
            $('#id_date').text(config.date);
            hostname = config.slaves[0];
            run_id = config.run_ids[0];

            create_all_buttons(config.slaves, config.run_ids);
            load_all_data();
        },
        read_config = function() {
            // Read config data, update page, then
            // create buttons and dstat charts
            $.ajax({
                type: "GET",
                url: "config.json",
                dataType: "json",
                success: function(data) {
                    config = data;
                    update_page(config);
                },
                error: function(request, status, error) {
                    console.log(error);
                }
            });
        };

    load_summary(); // Create the summary chart
    read_config();

})();
