function create_all_charts(arr) {

    for(i = 0; i < arr.length; i++) {
        cpu_mem_chart(arr[i])
    }      
}

cpu_mem_chart = function(obj){
  var id = obj.id,
      csv_filename = obj.filename;
  
  // Add h3 title
  $('<h3></h3>', {
    text: "Process " + id,
  }).appendTo('body');
  
  // Add chart div
  div = $('<div></div>',{
    class: "chart",
    id: "id_" + id
  }).appendTo('body');
  
  //Create c3js chart
  var chart = c3.generate({
    bindto: "#id_" + id,
    data: {
      url: csv_filename,
      x: 'elapsed_time_sec',
      names: {
        mem_pct: 'Memory',
        cpu_pct: 'CPU'
      },
    },
    type: 'line'
    ,
    axis: {
      y: {
        min: 0,
        max: 100,
        label: 'Usage [ % ]',
      },
      x: {
        min: 0,
        max: 60,
        label: 'Elapsed time [ sec ]',
      }
    }
  }); 
}

create_all_charts(chartdata);


