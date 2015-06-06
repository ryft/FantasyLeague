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
    my ($metric, $split_id) = @_;
    my $splits = splits;

    # Data configuration
    my $aggregation = 'cumulative';
    my $normalise = 0;

    # Ensure metric is valid
    warn $metric;
    $METRICS{$metric} or $metric = 'won';
    warn $metric;
    
    # Filter by split if provided and valid
    my ($split_filter, @params) = ('1');
    $split_id = 0 unless (defined $split_id and (grep {$_->{id} == $split_id} @$splits));
    if ($split_id != 0) {
        $split_filter = 'split = ?';
        push @params, $split_id;
    }

    my $summoners = $dbh->selectall_arrayref(qq{
        SELECT DISTINCT s.id, name
        FROM summoner s
            JOIN matchup m ON s.id IN (summoner1, summoner2)
            JOIN result r USING (split, week)
        WHERE $split_filter
        ORDER BY s.id
    }, { Slice => {} }, @params);
    my $weeks = $dbh->selectcol_arrayref(qq{
        SELECT DISTINCT CONCAT("S", split, " W", week)
        FROM result
        WHERE $split_filter
        GROUP BY split, week
        ORDER BY split, week
    }, {}, @params);

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
        WHERE $split_filter
            AND r1.summoner = m.summoner1
            AND r2.summoner = m.summoner2
        ORDER BY id, split, week
    }, [qw/split week id/], {}, @params);
    
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
                $summoner->{$metric} /= $summoner->{games} if ($normalise);
            }

            # Calculate mean and store it for the cumulative mean
            my $mean = sum( map { $_->{$metric} } values(%$week) ) / values(%$week);
            push @week_means, $mean;

            for my $summoner (values %$week) {
                my $result   = $results{$summoner->{id}};

                # Calculate value for this week based on given parameters
                if ($aggregation eq 'mean') {
                    $result->[$week_index] = $summoner->{$metric} - $mean;

                } elsif ($aggregation eq 'mean_cumulative') {
                    $result->[$week_index] = $summoner->{$metric} - (sum(@week_means) / @week_means);

                } elsif ($aggregation eq 'cumulative') {
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

# Prepare routes
get '/standings/'           => sub { my $c = shift; $c->stash(page => 'standings', split => 0); $c->render(template => 'standings') };
get '/standings/*split'     => sub { my $c = shift; $c->stash(page => 'standings'); $c->render(template => 'standings') };

get '/graph/:metric/'           => sub { my $c = shift; $c->stash(page => 'graphs', split => 0); $c->render(template => 'graph') };
get '/graph/:metric/:split'     => sub { my $c = shift; $c->stash(page => 'graphs'); $c->render(template => 'graph') };

get '/api/standings'        => sub { my $c = shift; $c->render(json => standings()) };
get '/api/standings/:split' => sub { my $c = shift; $c->render(json => standings($c->param('split'))) };

get '/api/:metric/'              => sub { my $c = shift; $c->render(json => data_series($c->param('metric'))) };
get '/api/:metric/:split'        => sub { my $c = shift; $c->render(json => data_series($c->param('metric'), $c->param('split'))) };

get '/'                     => sub { my $c = shift; $c->redirect_to('standings') };

app->secrets($config->{secrets});
app->start;

