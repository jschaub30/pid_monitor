cpu_chart = function(id, csv_fn){
  id = id.replace(/ /g, '_');  // Replace all spaces
  // Add h3 title
  $('<h3></h3>', {
    text: id,
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
      url: csv_fn,
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
}

cpu_chart('CPU', 'cpu_pct.csv');

cpu_chart('Memory', 'mem_pct.csv');


