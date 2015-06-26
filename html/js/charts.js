// First read configuration from a file and update HTML
var xlabel,
    slave,
    run_id;

$.ajax({
  type: "GET",
  url: "config.json",
  dataType: "json",
  success: function(data) {
    // console.log(data);
    xlabel = data["xlabel"];
    
    $('#id_workload').text(data["description"]);
    $('#id_title').text(data["workload"]);
    $('#id_date').text(data["date"]);
    slave = data["slaves"][0];
    run_id = data["run_ids"][0];

    load_csv();
    create_buttons(data["slaves"], data["run_ids"]);
    
  },
  error: function (request, status, error) {
    console.log(error);
  }
});


var parse_summary_line = function(line) {
  return {x:line['run_id'].split('=')[1].split('.')[0],  //threads
          y:line['elapsed_time_sec']}
}

function load_summary(){
  //Read summary data and create charts
  $.ajax({
    type: "GET",
    url: "summary.csv",
    dataType: "text",
    success: function(data) {
      var csv_data = $.csv.toObjects(data);
      // console.log(csv_data);
      csv_data     = csv_data.map(parse_summary_line);  // OPTIONALLY CUSTOMIZE EACH LINE
      // console.log(csv_data);
      setTimeout(function () {
        summary_chart(csv_data, "#id_all_data");
      });
    },
    error: function (request, status, error) {
      console.log(error);
    }
  });
};

load_summary();

function summary_chart (data, id){
  //console.log(id);
  //console.log(data);
  
  c3.generate({
    bindto: id,
    size: {
            height: 400,
  },
    data: {
      json: data,
      keys: {
        x: 'x',
        value: ['y'],
      },
      names: {
        y: 'Elapsed time [ sec ]',
      },
      type: "line",
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
        // type: 'category',
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
}

function csv_chart(data, id, title, labels, ylabel) {
  //console.log('csv_chart');
  //console.log(data);
  chart = new Dygraph(
    document.getElementById(id),
    data, 
    {
      labels: labels,
      //http://colorbrewer2.org/  <- qualitative, 6 classes
      colors: ['rgb(228,26,28)','rgb(55,126,184)','rgb(77,175,74)','rgb(152,78,163)','rgb(255,127,0)','rgb(141,211,199)'],
      xlabel: "Elapsed time [ sec ]",
      ylabel: ylabel,
      strokeWidth: 2,
      legend: 'always',
      labelsDivWidth: 500,
      title: title
    }
  )
  return chart
}

var time0 = -1,
    header_lines; // Used in error message in parse_line()

var parse_line = function() {
  var line = arguments[0],
  i = arguments[1],
  factor = arguments[2],
  day,
  month,
  time,
  arr,
  time_ms;
  
  try {
    day = line.time.split('-')[0];
    month = line.time.split('-')[1].split(' ')[0];
    time = line.time.split(' ')[1].split(':');
    arr = [];
    //time_str = "2015-" + month + '-' + day + ' ' + time
    time_ms = new Date ("2015", month, day , time[0], time[1], time[2]);
    //console.log(time_str);
    //time_ms = Date.parse(time_str);
    // console.log(time_ms);
    if (time0 == -1) {
      time0 = time_ms;
    }
    // console.log((time_ms - time0) / 1000);
    arr.push((time_ms - time0) / 1000);

    for (var i = 3; i < arguments.length; i++) {
      arr.push(factor * line[arguments[i]]);
    }
  }
  catch(err) {
    var err_str = "Problem reading CSV file near line " + (i + header_lines) + '<br>'
    err_str += JSON.stringify(line) + "<br>" + err.message;
    $("#id_error").html(err_str);
  }
  return arr
}

function load_csv() {
  url = '../data/raw/' + run_id + '.' + slave + '.dstat.csv';
  console.log(url);
  //Read csv data 
  //console.log('load_csv');
  $.ajax({
    type: "GET",
    url: url,
    dataType: "text",
    success: function(data) {
      var i = 0,
      flag = true,
      lines = data.split('\n');

      while (flag) {
        if (lines[i].indexOf("system") != -1) {
          flag = false;
        }
        i += 1;
      }
      var labels = lines[i],
      header = lines.slice(0, i-2),
      body = lines.slice(i, lines.length);
      
      header = header.join([separator = '<br>']);
      //$("#id_header").html(header);
      header_lines = i;  // Used in error message in parse_line()

      time0 = -1;
      var csv_data = $.csv.toObjects(body.join([separator = '\n']));
      // console.log(csv_data);
      cpu_data = csv_data.map(
        function(x, i) {
          return parse_line(x, i, 1, "usr", "sys", "idl", "wai", "hiq", "siq");
        }
      );
      mem_data = csv_data.map(
        function(x, i) {
          return parse_line(x, i, 1e-9, "used", "buff", "cach", "free");
        }
      );
      io_data = csv_data.map(
        function(x, i) {
          return parse_line(x, i, 1e-6, "read", "writ");
        }
      );
      net_data = csv_data.map(
        function(x, i) {
          return parse_line(x, i, 1e-6, "recv", "send");
        }
      );
      sys_data = csv_data.map(
        function(x, i) {
          return parse_line(x, i, 1, "int", "csw");
        }
      );
      proc_data = csv_data.map(
        function(x, i) {
          return parse_line(x, i, 1, "run", "blk", "new");
        }
      );
      pag_data = csv_data.map(
        function(x, i) {
          return parse_line(x, i, 1, "in", "out");
        }
      );
        
      csv_chart(cpu_data, "id_cpu", "CPU", ["time", "user", "system", "idle", "wait", "hiq", "siq"], "Usage [ % ]")
      csv_chart(mem_data, "id_mem", "Memory", ["time", "used", "buff", "cache", "free"], "Usage [ GB ]")
      csv_chart(io_data, "id_io", "IO", ["time", "read", "write"], "Usage [ MB/s ]")
      csv_chart(net_data, "id_net", "Network", ["time", "recv", "send"], "Usage [ MB/s ]")
      csv_chart(sys_data, "id_sys", "System", ["time", "interrupts", "context switches"], "")
      csv_chart(proc_data, "id_proc", "Processes", ["time", "run", "blk", "new"], "")
      csv_chart(pag_data, "id_pag", "Paging", ["time", "in", "out"], "")
    },
    error: function(request, status, error) {
      console.log(status);
      console.log(error);
    }
  });
};

function create_buttons(slaves, run_ids){
  for (i in slaves){
    create_cluster_button(i, slaves[i])
  }
  for (i in run_ids){
    create_button(i, run_ids[i])
  }
}

function create_cluster_button(i, id){
  var button_id = "cluster_button" + String(i),
  button    = $('<button></button>', {
    id:button_id,
    text:id
  }).appendTo('#cluster_buttons').addClass('button');

  if (i==0){
    button.addClass('active')
  }
  $("#" + button_id).on('click', function(){
    $this = $(this);
    $this.addClass('active');
    $this.siblings('button').removeClass('active');
    slave = id;
    setTimeout(function () {
      load_csv()
    }, 500);
  })
}

function create_button(i, id){
  var button_id = "button" + String(i),
  button    = $('<button></button>', {
    id:button_id,
    text:id
  }).appendTo('#buttons').addClass('button');
    
  if (i==0){
    button.addClass('active')
  }
  $("#" + button_id).on('click', function(){
    $this = $(this);
    $this.addClass('active');
    $this.siblings('button').removeClass('active');
    run_id = id;
    setTimeout(function () {
      load_csv()
    }, 500);
  })
}
