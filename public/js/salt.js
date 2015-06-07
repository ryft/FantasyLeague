var app = angular.module('SaltApp', ['chart.js', 'ui.bootstrap-slider']);

app.controller('StandingsCtrl', function($scope, $attrs, $http) {
    $http.get('/api/standings/' + $attrs.split)
        .success(function(response) {
            $scope.standings = response;
            $scope.predicate = '[splits, won, tied, pf, pa]';
            $scope.reverse   = true;
        }
    );
});

app.controller('ResultsCtrl', function($scope, $attrs, $http) {
    $scope.entities = [];

    $http.get('/api/entities/' + $attrs.split)
        .success(function(response) {
            $scope.entities = response;
            $scope.entities.forEach(function(e) {
                e.selected = true;
            });
        }
    );

    $scope.reloadData = function() {
        var api_url = '/api/results/' + $attrs.split + '?e='
            + $scope.entities.filter(function(e) { return e.selected })
                .map(function(e) { return e.id }).join(',');
        console.log(api_url);
        $http.get(api_url)
            .success(function(response) {
                $scope.results = response;
            }
        );
    };

    $scope.$watch('entities', $scope.reloadData, true);
});

app.controller('ChartCtrl', function($scope, $attrs, $http) {
    $scope.aggregation   = $attrs.aggregation;
    $scope.normalise     = $attrs.normalise == 'true';
    $scope.movingAverage = parseInt($attrs.movingAverage);
    $scope.showControls  = $.inArray($attrs.metric, ['pf', 'pa', 'pd']) >= 0;

    $scope.reloadGraph = function() {
        var api_url = '/api/' + $attrs.metric + '/' + $attrs.split + '?' + [
            'a=' + $scope.aggregation,
            'n=' + $scope.normalise,
            'm=' + $scope.movingAverage,
        ].join('&');

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

