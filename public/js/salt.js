var app = angular.module('SaltApp', ['chart.js']);

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

app.controller('ChartCtrl', function($scope, $attrs) {
    $scope.labels = ["January", "February", "March", "April", "May", "June", "July"];
    $scope.series = ['Series A', 'Series B'];
    $scope.data = [
        [65, 59, 80, 81, 56, 55, 40],
        [28, 48, 40, 19, 86, 27, 90]
    ];
});

//app.controller('treeController', function($scope, $filter, $http) {
//    var ipv4Filter = function(input) {
//        return input.slice(-4).join('.');
//    };
//    var userKeys = [
//        { name: 'name',         title: 'User name'      },
//        { name: 'release',      title: 'Client version' },
//        { name: 'os',           title: 'Operating system' },
//        { name: 'osversion',    title: 'OS version'     },
//        { name: 'onlinesecs',   title: 'Online time',   filter: 'interval' },
//        { name: 'idlesecs',     title: 'Last activity', filter: 'ago' },
////        { name: 'address',      title: 'IP address',    filter: 'ipv4' },
//    ];
//    var channelKeys = [
//        { name: 'name',         title: 'Channel name'   },
//        { name: 'id',           title: 'Channel ID'     },
//        { name: 'description',  title: 'Description'    },
//    ];
//
//    $scope.summary = 'Select a user or channel for details';
//    $scope.onTreeReady = function(e, data) {
//        $('#treeView').on('changed.jstree', function (e, data) {
//            if (data.action == 'select_node') {
//                var node = data.node.original;
//                $http.get('/api/node.php?type=' + node.type + '&id=' + node.id)
//                    .success(function(response) {
//                        $scope.summary  = '';
//                        $scope.info     = [];
//
//                        // Select data keys depending on node type
//                        var keys = (node.type == 'user') ? userKeys : channelKeys;
//                        angular.forEach(keys, function(item) {
//                            var val = response[item.name];
//
//                            this.push({
//                                title: item.title,
//                                value: $filter(item.filter || 'identity')(val),
//                            });
//                        }, $scope.info);
//                    }
//                );
//            } else {
//                console.log("Unhandled action " + data.action);
//            }
//        });
//    };
//});

