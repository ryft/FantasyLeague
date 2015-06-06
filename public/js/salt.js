var app = angular.module('SaltApp', ['chart.js', 'ui.bootstrap-slider']);

app.controller('StandingsCtrl', function($scope, $attrs, $http) {
    var api_url = ($attrs.split) ? '/api/standings/' + $attrs.split : '/api/standings';
    $http.get(api_url)
        .success(function(response) {
            $scope.standings = response;
            $scope.predicate = '[splits, won, tied, pf, pa]';
            $scope.reverse   = true;
        }
    );
});

app.controller('ChartCtrl', function($scope, $attrs, $http) {
    $scope.aggregation   = $attrs.aggregation;
    $scope.normalise     = $attrs.normalise == 'true';
    $scope.movingAverage = parseInt($attrs.movingAverage);
    $scope.canNormalise =  $.inArray($attrs.metric, ['pf', 'pa', 'pd']) >= 0;

    $scope.reloadGraph = function() {
        var api_url = '/api/' + $attrs.metric + '/' + $attrs.split + '?' + [
            'a=' + $scope.aggregation,
            'n=' + $scope.normalise,
            'm=' + $scope.movingAverage,
        ].join('&');
        console.log(api_url);

        $http.get(api_url)
            .success(function(response) {
                $scope.labels = response.labels;
                $scope.series = response.series;
                $scope.data   = response.data;
            }
        );
    };

    $scope.$watchGroup(['aggregation', 'normalise'], $scope.reloadGraph);
});

