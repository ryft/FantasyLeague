var app = angular.module('SaltApp', ['chart.js', 'ui.bootstrap-slider', 'frapontillo.gage', 'xeditable']);

app.controller('MetaCtrl', function($scope, $http) {
    $http.get('/api/entities/0').success(function(response) {
        $scope.summoners = response;
    });
});

app.controller('StandingsCtrl', function($scope, $attrs, $http) {
    $http.get('/api/standings/' + $attrs.split).success(function(response) {
        $scope.standings = response;
        $scope.predicate = '[splits, won, tied, pf, pa]';
        $scope.reverse   = true;
    });
});

app.controller('ResultsCtrl', function($scope, $attrs, $http) {
    $scope.entities = [];

    $http.get('/api/entities/' + $attrs.split).success(function(response) {
        $scope.entities = response;
        $scope.entities.forEach(function(e) {
            e.selected = true;
        });
    });

    $scope.reloadData = function() {
        var api_url = '/api/results/' + $attrs.split + '?e='
            + $scope.entities.filter(function(e) { return e.selected })
                .map(function(e) { return e.id }).join(',');
        $http.get(api_url).success(function(response) {
            $scope.results = response;
        });
    };

    $scope.$watch('entities', $scope.reloadData, true);
});

app.controller('SummonerCtrl', function($scope, $attrs, $http) {
    $scope.gaugeColours = ['#ffffff'];
    Chart.defaults.global.colours = ['#ffffff'];
    $http.get('/api/entities/' + $attrs.split).success(function(response) {
        $scope.entity = jQuery.grep(response, function(e) { return (e.id == $attrs.summoner) }).pop();
    });
    $http.get('/api/summoner/' + $attrs.summoner + '/' + $attrs.split).success(function(response) {
        $scope.head_to_heads = response.head_to_heads;
        $scope.final_rank = response.final_rank;
        $scope.win_ratio = response.win_ratio;
        $scope.players = response.players;
        $scope.labels = response.labels;
        $scope.ranks = [response.ranks];
    });
    $scope.updateTeamName = function(name) {
        var prevName = $scope.entity.name;
        console.log("Updating " + $attrs.split + " from " + prevName + " to " + name);
        $http.post('/api/updateTeam/' + $attrs.split, JSON.stringify({
            summoner: $scope.entity.id, name: name
        })).error(function() { $scope.entity.name = prevName });
    };
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

        $http.get(api_url).success(function(response) {
            $scope.labels = response.labels;
            $scope.series = response.series;
            $scope.data   = response.data;
        });
    };

    $scope.$watchGroup(['aggregation', 'normalise'], $scope.reloadGraph);
});

app.run(function(editableOptions) {
      editableOptions.theme = 'bs3';
});

