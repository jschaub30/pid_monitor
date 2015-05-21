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
    
    load_summary();
    build_charts(data["run_ids"]);
    
  },
  error: function (request, status, error) {
    console.log(error);
  }
});

var parse_line = function(line) {
  // console.log(line.run_id)
  return {x:line.run_id.split('=')[1].split('.')[0],  //threads
          y:line.elapsed_time_sec}
}

var calculate_mean = function(data) {
  var x_unique     = new Array(),
  x_array          = new Array(),
  y_array          = new Array();
  for (var i       = 0; i < data.length; i++){
    x_array.push(data[i].x);
    y_array.push(data[i].y);
    if (x_unique.indexOf(data[i].x) == -1) {
      x_unique.push(data[i].x);
    }
  }
  // console.log(x_unique);

  var sum,
  idx,
  count,
  avg,
  newData          = new Array();

  for (i           = 0; i < x_unique.length; i++){
    idx            = x_array.indexOf(x_unique[i]);
    sum            = 0;
    count          = 0;
    while (idx != -1) {
      sum         += Number(y_array[idx]);
      count       += 1;
      x_array.splice(idx, 1);
      y_array.splice(idx, 1);
      idx          = x_array.indexOf(x_unique[i]);
    }
    avg            = Math.round(100 * sum / count)/100;
    newData[i]     = {x:Number(x_unique[i]), y:avg}
  }
  // console.log(newData);
  return newData;
}

function load_summary(){
  //Read summary data and create charts
  $.ajax({
    type: "GET",
    url: "time_summary_csv",
    dataType: "text",
    success: function(data) {
      var csv_data = $.csv.toObjects(data);
      // console.log(csv_data);
      csv_data     = csv_data.map(parse_line);  // OPTIONALLY CUSTOMIZE EACH LINE
      avg_data     = calculate_mean(csv_data);
      // console.log(csv_data);
      setTimeout(function () {
        // summary_chart(avg_data, "line", "#id_summary");
        summary_chart(csv_data, "scatter", "#id_all_data");
      });
    },
    error: function (request, status, error) {
      console.log(error);
    }
  });
};


function summary_chart (data, chart_type, id){
  // console.log(id);
//   console.log(data);
  
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
      type: chart_type,
    },
    grid: {
      // x: {
      //   show: true
      // },
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
        label: xlabel,
      },
      y: {
        min: 0,
        // max: 100,
        label: 'Elapsed execution time [ seconds ]',
      },
    }
  });
}

function csv_chart (csv_fn, chart_type, id, ylabel){
  
  var chart = c3.generate({
    bindto: id,
    size: {
            height: 400,
      },
      data: {
      url: csv_fn,
      x: 'elapsed_time_sec',
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
        min: 0,
        //max: 100,
        label: 'Elapsed time [ sec ]',
      },
      y: {
        min: 0,
        // max: 100,
        label: ylabel,
      },
    }
  });
  return chart
}

function build_charts(run_ids) {
  var cpu_csv_fn  = 'data/' + run_ids[0] + '.cpu.csv',
  mem_csv_fn  = 'data/' + run_ids[0] + '.mem.csv',
  io_csv_fn   = 'data/' + run_ids[0] + '.io.csv',
  net_csv_fn  = 'data/' + run_ids[0] + '.net.csv';
  
  var cpu_chart = csv_chart(cpu_csv_fn, "line", "#id_cpu", "Usage [ % ]"),
      mem_chart = csv_chart(mem_csv_fn, "line", "#id_mem", "Usage [ GB ]"),
      io_chart  = csv_chart(io_csv_fn, "line", "#id_io", "Usage [ MB/s ]");
      net_chart = csv_chart(net_csv_fn, "line", "#id_net", "Usage [ MB/s ]");


  for (i in run_ids){
    create_button(i, run_ids)
  }

  function create_button(i, run_ids){
    var id        = run_ids[i],
    button_id = "button" + String(i),
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
      setTimeout(function () {
        cpu_chart.unload();
        mem_chart.unload();
        io_chart.unload();
        net_chart.unload();
      }, 500);
      setTimeout(function () {
        cpu_chart.load({
          url: 'data/' + id + '.cpu.csv'
        });
        mem_chart.load({
          url: 'data/' + id + '.mem.csv'
        });
        io_chart.load({
          url: 'data/' + id + '.io.csv'
        });
        net_chart.load({
          url: 'data/' + id + '.net.csv'
        });
      }, 1000);
    })
  }
}
