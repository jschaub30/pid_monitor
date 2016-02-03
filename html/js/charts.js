(function() {
    "use strict";
    var xlabel,
        hostname,
        run_id,
        time0 = -1,
        header_lines,
        data_dir,
        cumsum_flag = false,
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
            //console.log('csv_chart');
            //console.log(data);
            var chart = new Dygraph(
                document.getElementById(id),
                data, {
                    labels: labels,
                    //http://colorbrewer2.org/  <- qualitative, 6 classes
                    colors: ['rgb(228,26,28)', 'rgb(55,126,184)', 'rgb(77,175,74)', 'rgb(152,78,163)', 'rgb(255,127,0)', 'rgb(141,211,199)'],
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
        membw_chart = function(data) {
            //console.log(data);
            var chart = new Dygraph(
                document.getElementById("id_membw"),
                data, {
                    // labels: labels,
                    //http://colorbrewer2.org/  <- qualitative, 6 classes
                    colors: ['rgb(228,26,28)', 'rgb(55,126,184)', 'rgb(77,175,74)', 'rgb(152,78,163)', 'rgb(255,127,0)', 'rgb(141,211,199)'],
                    xlabel: "Elapsed time [ sec ]",
                    // ylabel: ylabel,
                    strokeWidth: 2,
                    legend: 'always',
                    labelsDivWidth: 500,
                    title: "Cache/Memory Bandwidth [ GB/s ]"
                }
            );
            return chart;
        },
        gpu_chart = function(id, data) {
            console.log(data);
            gpu.show();
            var title_str = "GPU Utilization [ % ]";
            var chart = new Dygraph(
                document.getElementById(id),
                data, {
                    // labels: labels,
                    //http://colorbrewer2.org/  <- qualitative, 6 classes
                    colors: ['rgb(228,26,28)', 'rgb(55,126,184)', 'rgb(77,175,74)', 'rgb(152,78,163)', 'rgb(255,127,0)', 'rgb(141,211,199)'],
                    xlabel: "Elapsed time [ sec ]",
                    // ylabel: ylabel,
                    strokeWidth: 2,
                    legend: 'always',
                    labelsDivWidth: 500,
                    title: title_str
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
                dt = new_array[i][0] - new_array[i-1][0];
                for (var j = 1; j < new_array[0].length; j++) {
                  new_array[i][j] = new_array[i-1][j] + dt*new_array[i][j];
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
            mem_data = csv_data.map(
                function(x, index) {
                    return parse_dstat_line(x, index, 1e-9, "used", "buff", "cach", "free");
                }
            );
            io_data = csv_data.map(
                function(x, index) {
                    return parse_dstat_line(x, index, 1e-6, "read", "writ");
                }
            );
            var io_sum_data = calc_cumsum(io_data);

            net_data = csv_data.map(
                function(x, index) {
                    return parse_dstat_line(x, index, 1e-6, "recv", "send");
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

            csv_chart(cpu_data, "id_cpu", "CPU", ["time", "user", "system", "idle", "wait", "hiq", "siq"], "Usage [ % ]");
            csv_chart(mem_data, "id_mem", "Memory", ["time", "used", "buff", "cache", "free"], "Usage [ GB ]");
            if (cumsum_flag) {
                csv_chart(io_sum_data, "id_io", "&#x222b; IO", ["time", "read", "write"], "Usage [ MB ]");
            } else {
                csv_chart(io_data, "id_io", "IO", ["time", "read", "write"], "Usage [ MB/s ]");
            }

            if (cumsum_flag) {
                csv_chart(net_sum_data, "id_net", "&#x222b; Network", ["time", "recv", "send"], "Usage [ MB ]");
            } else {
                csv_chart(net_data, "id_net", "Network", ["time", "recv", "send"], "Usage [ MB/s ]");
            }

            csv_chart(sys_data, "id_sys", "System", ["time", "interrupts", "context switches"], "");
            csv_chart(proc_data, "id_proc", "Processes", ["time", "run", "blk", "new"], "");
            csv_chart(pag_data, "id_pag", "Paging", ["time", "in", "out"], "");
            load_membw_csv();
            load_gpu_csv();
            load_gpu_mem_csv();
            $('#id_progress').hide();
        },
        load_dstat_csv = function() {
            // Read dstat data based on current value of 'run_id'
            // and 'hostname'
            var url = data_dir + '/' + run_id + '.' + hostname + '.dstat.csv';
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
        load_membw_csv = function() {
            var url = data_dir + '/' + run_id + '.' + hostname + '.ocount.memory_bw.csv';
            // console.log(url);
            //Read csv data
            $.ajax({
                type: "GET",
                url: url,
                dataType: "text",
                success: membw_chart,
                error: function(request, status, error) {
                    // console.log(status);
                    // console.log(error);
                    console.log('Ocount data not found');
                }
            });
        },
        load_gpu_csv = function() {
            var url = data_dir + '/' + run_id + '.' + hostname + '.gpu.csv';
            console.log(url);
            //Read csv data
            $.ajax({
                type: "GET",
                url: url,
                dataType: "text",
                success: function(data) {
                    gpu_chart("id_gpu", data);
                },
                error: function(request, status, error) {
                    // console.log(status);
                    // console.log(error);
                    console.log('GPU data not found');
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
                    load_dstat_csv();
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
                    load_dstat_csv();
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
                    load_dstat_csv();
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
        update_page = function(data, showTest) {
            // console.log(data);
            if (showTest) {
                var msg = 'Problem with config.json file.<br>';
                msg += 'Loading test data.';
                $('#id_error').html(msg);
            }
            xlabel = data.xlabel;
            data_dir = '../data/raw';
            if (data.hasOwnProperty('data_dir')) {
                data_dir = data.data_dir;
            }

            $('#id_workload').text(data.description);
            $('#id_title').text(data.workload);
            $('#id_date').text(data.date);
            hostname = data.slaves[0];
            run_id = data.run_ids[0];

            create_all_buttons(data.slaves, data.run_ids);
            load_dstat_csv();
            load_membw_csv();
            load_gpu_csv();
        },
        read_config = function() {
            // Read config data, update page, then
            // create buttons and dstat charts
            $.ajax({
                type: "GET",
                url: "config.json",
                dataType: "json",
                success: function(data) {
                    update_page(data);
                },
                error: function(request, status, error) {
                    //if problem with config.json, try config.test.json
                    $.ajax({
                        type: "GET",
                        url: "config.test.json",
                        dataType: "json",
                        success: function(data) {
                            update_page(data, true);
                        },
                        error: function(request, status, error) {
                            console.log(error);
                        }
                    });
                }
            });
        };

    load_summary();
    read_config();

})();
