
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
