#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use YAML::XS qw/LoadFile/;

use Mojolicious::Lite;

my $config = LoadFile('config.yaml');
my $db_cfg = $config->{mysql};
my $dbh = DBI->connect("dbi:mysql:$db_cfg->{database}",
    $db_cfg->{username},
    $db_cfg->{password},
    { mysql_auto_reconnect => 1 }
) or die $DBI::errstr;

sub splits {
    return $dbh->selectall_arrayref(q{
        SELECT * FROM split
    }, { Slice => {} });
}

sub standings {
    my $split_id = shift;
    my $splits = splits;
    my $standings = [];
    
    # Filter by split if provided and valid
    my ($split_filter, @params) = ('');
    $split_id = 0 unless (defined $split_id and (grep {$_->{id} == $split_id} @$splits));
    if ($split_id != 0) {
        $split_filter = 'AND split = ?';
        push @params, $split_id;
    }

    $standings = $dbh->selectall_arrayref(qq{
        SELECT s.id, s.name, COUNT(DISTINCT split) splits,
            SUM(IF ((r1.score > r2.score AND summoner1 = s.id) OR (r2.score > r1.score AND summoner2 = s.id), 1, 0)) won,
            SUM(IF  (r1.score = r2.score, 1, 0)) tied,
            SUM(IF ((r1.score > r2.score AND summoner2 = s.id) OR (r2.score > r1.score AND summoner1 = s.id), 1, 0)) lost,
            SUM(IF (summoner1 = s.id, r1.score, r2.score)) pf,
            SUM(IF (summoner1 = s.id, r2.score, r1.score)) pa
        FROM summoner s
            JOIN matchup m on s.id = summoner1 OR s.id = summoner2
            JOIN result r1 using (split, week)
            JOIN result r2 using (split, week)
        WHERE s.id in (summoner1, summoner2)
            AND r1.summoner = m.summoner1
            AND r2.summoner = m.summoner2
            $split_filter
        GROUP BY s.id
    }, { Slice => {} }, @params);

    for my $summoner (@$standings) {
        # Calculate the points difference per summoner
        $summoner->{pd} = $summoner->{pf} - $summoner->{pa};
        # Get the number of split wins per summoner
        $summoner->{splits} = scalar grep {$_->{winner} == $summoner->{id}} @$splits;
        # Convert strings to numbers for table sorting
        $summoner->{$_} += 0.0 for qw/splits won tied lost pf pa pd/;
    }

    return $standings;
}

sub data_series {
    my ($function, $split_id) = @_;
    my $splits = splits;

    # Data configuration
    my $metric = 'pf';
    my $aggregation = 'cumulative';
    my $normalise = 0;
    
    # Filter by split if provided and valid
    my ($split_filter, @params) = ('1');
    $split_id = 0 unless (defined $split_id and (grep {$_->{id} == $split_id} @$splits));
    if ($split_id != 0) {
        $split_filter = 'split = ?';
        push @params, $split_id;
    }

    my $summoners = $dbh->selectcol_arrayref(qq{
        SELECT DISTINCT name
        FROM summoner s
        JOIN matchup m ON s.id IN (summoner1, summoner2)
        JOIN result r USING (split, week)
        WHERE $split_filter
        ORDER BY s.id
    }, {}, @params);
    my $weeks = $dbh->selectcol_arrayref(qq{
        SELECT DISTINCT CONCAT("S", split, " W", week)
        FROM result
        WHERE $split_filter
        GROUP BY split, week
        ORDER BY split, week
    }, {}, @params);

    my $data = $dbh->selectall_hashref(qq{
        SELECT s.id, s.name, split, week,
            IF ((r1.score > r2.score AND summoner1 = s.id) OR (r2.score > r1.score AND summoner2 = s.id), 1, 0) won,
            IF  (r1.score = r2.score, 1, 0) tied,
            IF ((r1.score > r2.score AND summoner2 = s.id) OR (r2.score > r1.score AND summoner1 = s.id), 1, 0) lost,
            IF (summoner1 = s.id, r1.score, r2.score) pf,
            IF (summoner1 = s.id, r2.score, r1.score) pa
        FROM summoner s
            JOIN matchup m ON s.id IN (summoner1, summoner2)
            JOIN result r1 USING (split, week)
            JOIN result r2 USING (split, week)
        WHERE $split_filter
            AND r1.summoner = m.summoner1
            AND r2.summoner = m.summoner2
        ORDER BY id, split, week
    }, [qw/id split week/], {}, @params);
    
    my @results = ();

    # Collect stats for summoners in each week
    for (sort keys %$data) {
        my $summoner = $data->{$_};
        my @result = ();
        my $total  = 0;

        for (sort keys %$summoner) {
            my $split = $summoner->{$_};
            for (sort keys %$split) {
                my $week = $split->{$_};

                $total = $aggregation eq 'cumulative'
                    ? $total + $week->{$metric} : $week->{$metric};
                push @result, $total;
            }
        }
        
        # Pad the result to the correct number of weeks
        #   This is necessary because some summoners joined late
        #   If summoners start leaving, it will be worthwhile to
        #   maintain a (split, week) -> week # mapping.
        unshift @result, (0) x (scalar @$weeks - scalar @result);
        push @results, \@result;
    }

#    return {
#        labels => ["January", "February", "March", "April", "May", "June", "July"],
#        series => ['Series A', 'Series B'],
#        data => [
#          [65, 59, 80, 81, 56, 55, 40],
#          [28, 48, 40, 19, 86, 27, 90]
#        ],
#    };

    return {
        labels => $weeks,
        series => $summoners,
        data   => \@results,
        #data   => [
        #    [3,4,6,3,2,3,4,5,3,6,4,3,2,1,3,4,5,3,2,6,3],
        #    [3,4,6,3,2,4,2,2,3,1,4,4,5,3,3,4,6,2,5,2,4],
        #    [3,4,6,3,2,3,4,5,3,6,4,3,2,1,3,4,5,3,2,6,3],
        #    [3,4,6,3,2,4,2,2,3,1,4,4,5,3,3,4,6,2,5,2,4],
        #    [3,4,6,3,2,3,4,5,3,6,4,3,2,1,3,4,5,3,2,6,3],
        #    [3,4,6,3,2,4,2,2,3,1,4,4,5,3,3,4,6,2,5,2,4],
        #    [3,4,6,3,2,3,4,5,3,6,4,3,2,1,3,4,5,3,2,6,3],
        #    [3,4,6,3,2,4,2,2,3,1,4,4,5,3,3,4,6,2,5,2,4],
        #],
    };
}

# Set up routes
get '/standings/'           => sub { my $c = shift; $c->stash(page => 'standings', split => 0); $c->render(template => 'standings') };
get '/standings/*split'     => sub { my $c = shift; $c->stash(page => 'standings'); $c->render(template => 'standings') };

get '/charts/pf/'           => sub { my $c = shift; $c->stash(page => 'charts/pf', split => 0); $c->render(template => 'chart-pf') };
get '/charts/pf/:split'     => sub { my $c = shift; $c->stash(page => 'charts/pf'); $c->render(template => 'chart-pf') };

get '/charts/pa/'           => sub { my $c = shift; $c->stash(page => 'charts/pa', split => 0); $c->render(template => 'standings') };
get '/charts/pa/:split'     => sub { my $c = shift; $c->stash(page => 'charts/pa'); $c->render(template => 'standings') };

get '/charts/pd/'           => sub { my $c = shift; $c->stash(page => 'charts/pd', split => 0); $c->render(template => 'standings') };
get '/charts/pd/:split'     => sub { my $c = shift; $c->stash(page => 'charts/pd'); $c->render(template => 'standings') };

get '/api/standings'        => sub { my $c = shift; $c->render(json => standings()) };
get '/api/standings/:split' => sub { my $c = shift; $c->render(json => standings($c->param('split'))) };

get '/api/pf'               => sub { my $c = shift; $c->render(json => data_series('pf')) };
get '/api/pf/:split'        => sub { my $c = shift; $c->render(json => data_series('pf', $c->param('split'))) };

get '/'                     => sub { my $c = shift; $c->redirect_to('standings') };

app->secrets($config->{secrets});
app->start;

