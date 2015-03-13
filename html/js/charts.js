// First read configuration from a file, then call build_charts

$.ajax({
  type: "GET",
  url: "config.clean.json",
  dataType: "json",
  success: function(data) {
    console.log(data);
    var config_list = $.trim(data).split('\n');
    
    $('#id_workload').text(data["workload"]);
    $('#id_title').text(data["workload"]);
    $('#id_date').text(data["date"]);
    build_charts(data["run_ids"]);
  },
  error: function (request, status, error) {
    console.log(error);
  }
});


var summary_chart = c3.generate({
  bindto: "#id_summary",
  data: {
    url: "summary.csv",
    x: 'run_id'
    // axes: {
    //   cpu_pct: 'y',
    //   elapsed_time_sec: 'y2'
    // }
  },
  type: 'line',
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
      // max: 60,
      // label: 'Elapsed time [ sec ]',
    },
    y: {
      min: 0,
      // max: 100,
      label: 'Elapsed execution time [ seconds ]',
    },
    // y2: {
    //   min: 0,
    //   show: true,
    //   label: 'Execution time [ seconds ]',
    // }
  }
});



function build_charts(run_ids) {
  var cpu_csv_fn  = run_ids[0] + '.cpu_pct.csv',
  mem_csv_fn  = run_ids[0] + '.mem_pct.csv';
  
  //Create c3js chart
  var cpu_chart = c3.generate({
    bindto: "#id_cpu",
    data: {
      url: cpu_csv_fn,
      x: 'x',
    },
    type: 'line',
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
      y: {
        // min: 0,
        // max: 100,
        label: 'Usage [ % ]',
      },
      x: {
        // min: 0,
        // max: 60,
        label: 'Elapsed time [ sec ]',
      }
    }
  });

  var mem_chart = c3.generate({
    bindto: "#id_mem",
    data: {
      url: mem_csv_fn,
      x: 'x',
    },
    type: 'line',
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
      y: {
        // min: 0,
        // max: 100,
        label: 'Usage [ % ]',
      },
      x: {
        // min: 0,
        // max: 60,
        label: 'Elapsed time [ sec ]',
      }
    }
  });

  for (i in run_ids){
    create_button(i, run_ids)
  }

  function create_button(i, run_ids){
    var id        = run_ids[i],
        button_id = "button" + String(i),
        button    = $('<button></button>', {
                      id:button_id,
                      text:id
                    }).insertBefore('#cpu_title').addClass('button');
    
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
      }, 500);
      setTimeout(function () {
        cpu_chart.load({
          url: id + '.cpu_pct.csv'
        });
        mem_chart.load({
          url: id + '.mem_pct.csv'
        });
      }, 1000);
    })
  }
}
