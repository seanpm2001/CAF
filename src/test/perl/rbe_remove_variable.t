# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/modules";
use testapp;
use CAF::FileEditor;
use CAF::RuleBasedEditor qw(:rule_constants);
use Readonly;
use CAF::Object;
use Test::More tests => 12;
use Test::NoWarnings;
use Test::Quattor;
use Carp qw(confess);

Test::NoWarnings::clear_warnings();


=pod

=head1 SYNOPSIS

Basic tests for rule-based editor (variable deletion)

=cut

Readonly my $DPM_CONF_FILE => "/etc/sysconfig/dpm";

Readonly my $DPM_INITIAL_CONF_1 => '# should the dpm daemon run?
# any string but "yes" will equivalent to "NO"
#
RUN_DPMDAEMON="yes"
#
# should we run with another limit on the number of file descriptors than the default?
# any string will be passed to ulimit -n
#ULIMIT_N=4096
#
###############################################################################################
# Change and uncomment the variables below if your setup is different than the one by default #
###############################################################################################

ALLOW_COREDUMP="yes"

#################
# DPM variables #
#################

# - DPM Name Server host : please change !!!!!!
#DPNS_HOST=grid05.lal.in2p3.fr

# - make sure we use globus pthread model
export GLOBUS_THREAD_MODEL=pthread
';

Readonly my $DPM_INITIAL_CONF_2 => $DPM_INITIAL_CONF_1 . '
# Duplicated line
ALLOW_COREDUMP="yes"
';

Readonly my $DPM_EXPECTED_CONF_1 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
# should the dpm daemon run?
# any string but "yes" will equivalent to "NO"
#
RUN_DPMDAEMON="yes"
#
# should we run with another limit on the number of file descriptors than the default?
# any string will be passed to ulimit -n
#ULIMIT_N=4096
#
###############################################################################################
# Change and uncomment the variables below if your setup is different than the one by default #
###############################################################################################

#ALLOW_COREDUMP="yes"

#################
# DPM variables #
#################

# - DPM Name Server host : please change !!!!!!
#DPNS_HOST=grid05.lal.in2p3.fr

# - make sure we use globus pthread model
#export GLOBUS_THREAD_MODEL=pthread
';

Readonly my $DPM_EXPECTED_CONF_2 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
# should the dpm daemon run?
# any string but "yes" will equivalent to "NO"
#
RUN_DPMDAEMON="yes"
#
# should we run with another limit on the number of file descriptors than the default?
# any string will be passed to ulimit -n
#ULIMIT_N=4096
#
###############################################################################################
# Change and uncomment the variables below if your setup is different than the one by default #
###############################################################################################

#ALLOW_COREDUMP="yes"

#################
# DPM variables #
#################

# - DPM Name Server host : please change !!!!!!
#DPNS_HOST=grid05.lal.in2p3.fr

# - make sure we use globus pthread model
export GLOBUS_THREAD_MODEL=pthread
';

Readonly my $DPM_EXPECTED_CONF_3 => $DPM_EXPECTED_CONF_1 . '
# Duplicated line
#ALLOW_COREDUMP="yes"
';


my %config_rules_1 = (
      "-ALLOW_COREDUMP" => "allowCoreDump:dpm;".LINE_FORMAT_SH_VAR.";".LINE_VALUE_BOOLEAN,
      "-GLOBUS_THREAD_MODEL" => "globusThreadModel:dpm;".LINE_FORMAT_ENV_VAR,
     );

my %config_rules_2 = (
      "ALLOW_COREDUMP" => "allowCoreDump:dpm;".LINE_FORMAT_SH_VAR.";".LINE_VALUE_BOOLEAN,
      "GLOBUS_THREAD_MODEL" => "globusThreadModel:dpm;".LINE_FORMAT_ENV_VAR,
     );

my %config_rules_3 = (
      "ALLOW_COREDUMP" => "!srmv22->allowCoreDump:dpm;".LINE_FORMAT_SH_VAR.";".LINE_VALUE_BOOLEAN,
      "GLOBUS_THREAD_MODEL" => "dpns->globusThreadModel:dpm;".LINE_FORMAT_ENV_VAR,
     );

my %config_rules_4 = (
      "?ALLOW_COREDUMP" => "allowCoreDump:dpm;".LINE_FORMAT_SH_VAR.";".LINE_VALUE_BOOLEAN,
      "GLOBUS_THREAD_MODEL" => "globusThreadModel:dpm;".LINE_FORMAT_ENV_VAR,
     );

my %parser_options = ("remove_if_undef" => 1);


#############
# Main code #
#############

$CAF::Object::NoAction = 1;
set_caf_file_close_diff(1);

our %opts = ();
our $path;
my ($log, $str);
my $this_app = testapp->new ($0, qw (--verbose));

$SIG{__DIE__} = \&confess;

*testapp::error = sub {
    my $self = shift;
    $self->{ERROR} = @_;
};


open ($log, ">", \$str);
$this_app->set_report_logfile ($log);

my $changes;
my $fh;


# Test negated keywords
my $dpm_options = {};
set_file_contents($DPM_CONF_FILE,$DPM_INITIAL_CONF_1);
my $fh = CAF::FileEditor->open($DPM_CONF_FILE, log => $this_app);
ok(defined($fh), $DPM_CONF_FILE." was opened");
$changes = $fh->updateFile(\%config_rules_1,
                           $dpm_options,
                           \%parser_options);
is("$fh", $DPM_EXPECTED_CONF_1, $DPM_CONF_FILE." has expected contents (negated keywords)");
$fh->close();

# Test removal of a config line is config option is not defined
$dpm_options = {"dpm" => {"globusThreadModel" => "pthread"}};
set_file_contents($DPM_CONF_FILE,$DPM_INITIAL_CONF_1);
my $fh = CAF::FileEditor->open($DPM_CONF_FILE, log => $this_app);
ok(defined($fh), $DPM_CONF_FILE." was opened");
$changes = $fh->updateFile(\%config_rules_2,
                           $dpm_options,
                           \%parser_options);
is("$fh", $DPM_EXPECTED_CONF_2, $DPM_CONF_FILE." has expected contents (config option not defined)");
$fh->close();

# Test removal of a config line is rule condition is not met
$dpm_options = {"dpm" => {"globusThreadModel" => "pthread"}};
set_file_contents($DPM_CONF_FILE,$DPM_INITIAL_CONF_1);
my $fh = CAF::FileEditor->open($DPM_CONF_FILE, log => $this_app);
ok(defined($fh), $DPM_CONF_FILE." was opened");
$changes = $fh->updateFile(\%config_rules_3,
                           $dpm_options,
                           \%parser_options);
is("$fh", $DPM_EXPECTED_CONF_1, $DPM_CONF_FILE." has expected contents (rule condition not met)");
$fh->close();

# Test removal of a config line is config option is not defined
# when keyword is prefixed by ?
$dpm_options = {"dpm" => {"globusThreadModel" => "pthread"}};
set_file_contents($DPM_CONF_FILE,$DPM_INITIAL_CONF_1);
my $fh = CAF::FileEditor->open($DPM_CONF_FILE, log => $this_app);
ok(defined($fh), $DPM_CONF_FILE." was opened");
$changes = $fh->updateFile(\%config_rules_4,
                           $dpm_options);
is("$fh", $DPM_EXPECTED_CONF_2, $DPM_CONF_FILE." has expected contents (rule keyword prefixed by ?)");
$fh->close();


# Test removal of config lines appearing multiple times
$dpm_options = {"dpm" => {"globusThreadModel" => "pthread"}};
set_file_contents($DPM_CONF_FILE,$DPM_INITIAL_CONF_2);
my $fh = CAF::FileEditor->open($DPM_CONF_FILE, log => $this_app);
ok(defined($fh), $DPM_CONF_FILE." was opened");
$changes = $fh->updateFile(\%config_rules_1,
                           $dpm_options,
                           \%parser_options);
is("$fh", $DPM_EXPECTED_CONF_3, $DPM_CONF_FILE." has expected contents (repeated config line)");
$fh->close();


Test::NoWarnings::had_no_warnings();
