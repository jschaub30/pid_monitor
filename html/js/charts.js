// First read configuration from a file, then call build_charts

$.ajax({
  type: "GET",
  url: "config.txt",
  dataType: "text",
  success: function(data) {
    var config_list = $.trim(data).split('\n');
    
    $('#id_workload').text(config_list[0].split(':')[1]);
    $('#id_date').text(config_list[1].split(':')[1]);
    var id_list;
    for (i in config_list.slice(2)){
      id_list[i] = config_list.slice(2).split(':')[1];
    }
    build_charts(config_list.slice(2));
  },
  error: function (request, status, error) {
    console.log(error);
  }
});


function build_charts(id_list) {
  var cpu_csv_fn  = id_list[0] + '.cpu_pct.csv',
  mem_csv_fn  = id_list[0] + '.mem_pct.csv';
  
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

  for (i in id_list){
    create_button(i, id_list)
  }

  function create_button(i, id_list){
    var id        = id_list[i],
        button_id = "button" + String(i),
        button    = $('<button></button>', {
                      id:button_id,
                      width:"180px",
                      height:"40px",
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



