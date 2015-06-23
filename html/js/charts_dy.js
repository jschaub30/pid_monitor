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
    build_charts(data["run_ids"][0]);
    create_buttons(data["run_ids"]);
    
  },
  error: function (request, status, error) {
    console.log(error);
  }
});

var parse_line = function(line) {
  // console.log(line.run_id)
  return [parseFloat(line.run_id.split('=')[1].split('.')[0]),  //threads
          parseFloat(line.elapsed_time_sec)]
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
      // avg_data     = calculate_mean(csv_data);
      // console.log(csv_data);
      setTimeout(function () {
        // summary_chart(avg_data, "line", "#id_summary");
        summary_chart(csv_data, "scatter", "id_all_data");
      });
    },
    error: function (request, status, error) {
      console.log(error);
    }
  });
};


function summary_chart (data, chart_type, id){
  console.log(data);
  chart = new Dygraph(
    document.getElementById(id),
    data, // path to CSV file
    {
      labels: ["Input size", "Elapsed time [ sec ]"],
      colors: ['rgb(228,26,28)','rgb(55,126,184)','rgb(77,175,74)','rgb(152,78,163)'],
      width: DIV_WIDTH,
      height: 400,
      drawPoints: true,
      strokeWidth: 2,
      xRangePad: 10,
      pointSize: 3
    }
  )
  return chart
}


function csv_chart (csv_fn, chart_type, id, ylabel){
  // console.log(DIV_WIDTH);
  chart = new Dygraph(
    document.getElementById(id),
    csv_fn, // path to CSV file
    {
      //http://colorbrewer2.org/
      colors: ['rgb(228,26,28)','rgb(55,126,184)','rgb(77,175,74)','rgb(152,78,163)'],
      width: DIV_WIDTH,
      height: 400,
      xlabel: "Elapsed time [ sec ]",
      ylabel: ylabel,
      strokeWidth: 2,
      legend: 'always',
      labelsDivWidth: 300
    }
  )
  return chart
}



function build_charts(run_id) {
  var cpu_csv_fn  = 'data/' + run_id + '.cpu.csv',
  mem_csv_fn  = 'data/' + run_id + '.mem.csv',
  io_csv_fn   = 'data/' + run_id + '.io.csv',
  net_csv_fn  = 'data/' + run_id + '.net.csv';
  
  var cpu_chart = csv_chart(cpu_csv_fn, "line", "id_cpu", "Usage [ % ]"),
      mem_chart = csv_chart(mem_csv_fn, "line", "id_mem", "Usage [ GB ]"),
      io_chart  = csv_chart(io_csv_fn, "line", "id_io", "Usage [ MB/s ]");
      net_chart = csv_chart(net_csv_fn, "line", "id_net", "Usage [ MB/s ]");

}

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

      build_charts(run_id)
    }, 500);
  })
}
