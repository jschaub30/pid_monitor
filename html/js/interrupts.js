(function() {
    "use strict";
    var load_int_detail = function() {
            $.ajax({
                type: "GET",
                // url: data_dir + '/' + run_id + '_' + hostname + '_int_detail.csv.js',
                // url: 'pcloud5.json',
                url: 'pcloud5Queue.json',
                dataType: "json",
                success: function(data) {
                    $("#id_int_heatmap").show();
                    var ctx = document.getElementById("id_int_detail").getContext("2d");
                    var sampleChart = new Chart(ctx).HeatMap(data, {
                        responsive: true,
                        maintainAspectRatio: false,
                        rounded: false,
                        paddingScale: 0.0,
                        showLabels: false,
                        showScale: false,
                        tooltipTemplate: "t: <%= xLabel %> | <%= yLabel %> | value: <%= value %>",
                        colorInterpolation: 'gradient',
                        colors: ['rgb(220,220,220)', 'red']
                    });
                    $('#id_int_y0').text(data.datasets[0].label);
                    // $('#id_int_y1').text(data.datasets[data.datasets.length - 1].label);
                    $('#id_int_x1').text(data.labels[data.labels.length - 1] + 's');
                    $('#id_int_x0').text(data.labels[0] + 's');
                },
                error: function(request, status, error) {
                    console.log(error);
                }
            });
        };

    load_int_detail();
})();
