// First read configuration from a file and update HTML
var xlabel;

$.ajax({
  type: "GET",
  url: "config.clean.json",
  dataType: "json",
  success: function(data) {
    // console.log(data);
    xlabel = data["xlabel"];
    
    $('#id_workload').text(data["description"]);
    $('#id_title').text(data["workload"]);
    $('#id_date').text(data["date"]);
    
    // load_summary();
    // build_charts(data["run_ids"][0]);
    load_csv(data["run_ids"][0]);
    create_buttons(data["run_ids"]);
    
  },
  error: function (request, status, error) {
    console.log(error);
  }
});


function summary_chart (id){
  chart = new Dygraph(
    document.getElementById(id),
    'formatted_time_summary', // path to CSV file
    {
      xlabel: "Input size", 
      ylabel: "Elapsed time [ sec ]",
      xRangePad: 20,
      drawPoints: true,
      pointSize: 3
    }
  )
  return chart
}

summary_chart("id_all_data")


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

function load_csv(run_id) {
  //Read csv data 
  //console.log('load_csv');
  $.ajax({
    type: "GET",
    url: 'data/' + run_id + '.dstat.csv',
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
      $("#id_header").html(header);
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

function create_buttons(run_ids){
  // console.log('Creating buttons');
  for (i in run_ids){
    // console.log(run_ids[i]);
    create_button(i, run_ids[i])
  }
}


function create_button(i, run_id){
  var button_id = "button" + String(i),
  button    = $('<button></button>', {
    id:button_id,
    text:run_id
  }).appendTo('#buttons').addClass('button');
    
  if (i==0){
    button.addClass('active')
  }
  $("#" + button_id).on('click', function(){
    $this = $(this);
    $this.addClass('active');
    $this.siblings('button').removeClass('active');
    setTimeout(function () {
      //could use chart.updateOptions here

      // build_charts(run_id)
      load_csv(run_id)
    }, 500);
  })
}
