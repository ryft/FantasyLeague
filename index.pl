#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dump qw/dump/;
use DBI;
use List::Util qw/sum/;
use Readonly;
use YAML::XS qw/LoadFile/;

use Mojolicious::Lite;

Readonly my $CONFIG => 'config.yaml';
Readonly my $DEFAULT_METRIC => 'won';
Readonly my %METRICS => {
    won     => 'Matches Won',
    tied    => 'Matches Tied',
    lost    => 'Matches Lost',
    pf      => 'Points For',
    pa      => 'Points Against',
    pd      => 'Points Difference',
};

my $config = LoadFile($CONFIG);
my $db_cfg = $config->{mysql};
my $dbh = DBI->connect("dbi:mysql:$db_cfg->{database}",
    $db_cfg->{username},
    $db_cfg->{password},
    { mysql_auto_reconnect => 1 }
) or die $DBI::errstr;

sub metric {
    my $metric = shift;
    return $METRICS{$metric} ? $metric : $DEFAULT_METRIC;
}

sub metric_name {
    my $metric = shift;
    return $METRICS{metric($metric)};
}

sub default_params {
    my $metric = shift;
    if (can_normalise($metric)) {
        return (
            aggregation    => 'raw',
            normalise      => 'true',
            moving_average => 1,
        );
    } else {
        return (
            aggregation    => 'cumulative',
            normalise      => 'false',
            moving_average => 1,
        );
    }
}

sub can_normalise { shift =~ /pf|pa|pd/ }

sub get_splits {
    return $dbh->selectall_arrayref(q{
        SELECT * FROM split
    }, { Slice => {} });
}

# Filter by split if provided and valid
# Returns (where clause, params)
sub filter_split_clause {
    my $split = shift;
    my $splits = get_splits;
    my ($sql, @params) = ('1');
    if ($split and (grep {$_->{id} == $split} @$splits)) {
        $sql = 'split = ?';
        push @params, $split;
    }
    return ($sql, @params);
}

sub get_standings {
    my ($split_clause, @params) = filter_split_clause shift;
    return $dbh->selectall_arrayref(qq{
        SELECT s.id, s.name, COUNT(DISTINCT split) splits,
            SUM(IF ((r1.score > r2.score AND summoner1 = s.id) OR (r2.score > r1.score AND summoner2 = s.id), 1, 0)) won,
            SUM(IF  (r1.score = r2.score, 1, 0)) tied,
            SUM(IF ((r1.score > r2.score AND summoner2 = s.id) OR (r2.score > r1.score AND summoner1 = s.id), 1, 0)) lost,
            SUM(IF (summoner1 = s.id, r1.score, r2.score)) pf,
            SUM(IF (summoner1 = s.id, r2.score, r1.score)) pa
        FROM summoner s
            JOIN matchup m ON s.id IN (summoner1, summoner2)
            JOIN result r1 USING (split, week)
            JOIN result r2 USING (split, week)
        WHERE $split_clause
            AND r1.summoner = m.summoner1
            AND r2.summoner = m.summoner2
        GROUP BY s.id
    }, { Slice => {} }, @params);
}

sub standings {
    my $splits    = get_splits;
    my $standings = get_standings shift;

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

sub get_results {
    my ($split_clause, @params) = filter_split_clause shift;
    return $dbh->selectall_arrayref(qq{
        SELECT split, week, s1.name summoner1, s2.name summoner2, r1.score points1, r2.score points2
        FROM matchup m
            JOIN summoner s1 ON s1.id = summoner1
            JOIN summoner s2 ON s2.id = summoner2
            JOIN result r1 USING (split, week)
            JOIN result r2 using (split, week)
        WHERE $split_clause
            AND r1.summoner = summoner1
            AND r2.summoner = summoner2
    }, { Slice => {} }, @params);
}

sub results {
    my $results = get_results shift;
    warn dump($results);

    for my $result (@$results) {
        # Convert strings to numbers for table sorting
        $result->{$_} += 0.0 for qw/split week points1 points2/;
    }
    return $results;
}

sub get_summoners {
    my ($split_clause, @params) = filter_split_clause shift;
    return $dbh->selectall_arrayref(qq{
        SELECT DISTINCT s.id, name
        FROM summoner s
            JOIN matchup m ON s.id IN (summoner1, summoner2)
            JOIN result r USING (split, week)
        WHERE $split_clause
        ORDER BY s.id
    }, { Slice => {} }, @params);
}

sub get_weeks {
    my ($split_clause, @params) = filter_split_clause shift;
    return $dbh->selectcol_arrayref(qq{
        SELECT DISTINCT CONCAT("S", split, " W", week)
        FROM result
        WHERE $split_clause
        GROUP BY split, week
        ORDER BY split, week
    }, {}, @params);
}

sub data_series {
    my ($metric, $split_id, %params) = @_;
    my $splits = get_splits;

    # Data configuration
    $params{aggregation}    ||= 'cumulative';
    $params{moving_average} ||= 4;
    $params{normalise}      ||= 'false';

    # Ensure metric is valid
    $METRICS{$metric} or $metric = $DEFAULT_METRIC;

    my ($split_clause, @params) = filter_split_clause $split_id;
    my $data = $dbh->selectall_hashref(qq{
        SELECT s.id, s.name, split, week, games,
            IF ((r1.score > r2.score AND summoner1 = s.id) OR (r2.score > r1.score AND summoner2 = s.id), 1, 0) won,
            IF  (r1.score = r2.score, 1, 0) tied,
            IF ((r1.score > r2.score AND summoner2 = s.id) OR (r2.score > r1.score AND summoner1 = s.id), 1, 0) lost,
            IF (summoner1 = s.id, r1.score, r2.score) pf,
            IF (summoner1 = s.id, r2.score, r1.score) pa
        FROM summoner s
            JOIN matchup m ON s.id IN (summoner1, summoner2)
            JOIN matches n USING (split, week)
            JOIN result r1 USING (split, week)
            JOIN result r2 USING (split, week)
        WHERE $split_clause
            AND r1.summoner = m.summoner1
            AND r2.summoner = m.summoner2
        ORDER BY id, split, week
    }, [qw/split week id/], {}, @params);

    my $weeks       = get_weeks $split_id;
    my $summoners   = get_summoners $split_id;
    
    # Initialise results hash
    my %results     = ();
    $results{$_}    = [(0) x @$weeks] for (map {$_->{id}} @$summoners);
    my @week_means  = ();
    my $week_index  = 0;

    for (sort {$a <=> $b} keys %$data) {
        my $split   = $data->{$_};

        for (sort {$a <=> $b} keys %$split) {
            my $week = $split->{$_};

            # Perform some pre-processing for this week's results
            for my $summoner (values %$week) {

                # Generate points difference metrics
                $summoner->{pd} = $summoner->{pf} - $summoner->{pa};

                # Normalise values before taking the mean
                $summoner->{$metric} /= $summoner->{games}
                    if ($params{normalise} eq 'true' and can_normalise($metric));
            }

            # Calculate mean and store it for the cumulative mean
            push @week_means, sum( map { $_->{$metric} } values(%$week) ) / values(%$week);
            shift @week_means if (@week_means > $params{moving_average});
            my $accumulated_mean = sum(@week_means) / @week_means;

            for my $summoner (values %$week) {
                my $result   = $results{$summoner->{id}};

                # Calculate value for this week based on given parameters
                if ($params{aggregation} eq 'deviation') {
                    $result->[$week_index] = $summoner->{$metric} - $accumulated_mean;

                } elsif ($params{aggregation} eq 'cumulative') {
                    $result->[$week_index] = $summoner->{$metric};
                    $result->[$week_index] += $result->[$week_index - 1] if ($week_index > 0);

                } else {
                    $result->[$week_index] = $summoner->{$metric};
                }
            }
            $week_index++;
        }
    }

    # Format the results into a 2D array for graphing
    my @output = map {$results{$_}} (sort keys %results);

    return {
        labels => $weeks,
        series => [ map {$_->{name}} @$summoners ],
        data   => \@output,
    };
}

# Prepare UI routes
get '/' => sub { my $c = shift; $c->redirect_to('standings/0') };
get '/standings/:split' => sub { my $c = shift; $c->stash(page => 'standings'); $c->render(template => 'standings') };
get '/results/:split'   => sub { my $c = shift; $c->stash(page => 'results');   $c->render(template => 'results') };
get '/graph/:metric/:split' => sub {
    my $c = shift;
    my $metric = metric($c->param('metric'));
    $c->stash(
        page    => "graph/$metric",
        title   => metric_name($metric),
        default_params($metric),
    );
    $c->render(template => 'graph');
};

# Prepare API routes
get '/api/standings/:split' => sub { my $c = shift; $c->render(json => standings($c->param('split'))) };
get '/api/results/:split'   => sub { my $c = shift; $c->render(json => results($c->param('split'))) };
get '/api/:metric/:split'   => sub {
    my $c = shift;
    $c->render(json => data_series(
        $c->param('metric'),
        $c->param('split'),
        aggregation    => $c->param('a'),
        normalise      => $c->param('n'),
        moving_average => $c->param('m'),
    ));
};

app->secrets($config->{secrets});
app->start;

