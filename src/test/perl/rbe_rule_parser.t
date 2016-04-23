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
use Test::More tests => 30;
use Test::NoWarnings;
use Test::Quattor;
use Carp qw(confess);

Test::NoWarnings::clear_warnings();


=pod

=head1 SYNOPSIS

Basic tests for rule-based editor (variable substitution)

=cut

Readonly my $DPM_CONF_FILE => "/etc/sysconfig/dpm";
Readonly my $DMLITE_CONF_FILE => "/etc/httpd/conf.d/zlcgdm-dav.conf";
Readonly my $DPM_SHIFT_CONF_FILE => "/etc/shift.conf";

Readonly my $DPM_INITIAL_CONF_1 => '# should the dpm daemon run?
# any string but "yes" will equivalent to "NO"
#
RUN_DPMDAEMON="no"
#
# should we run with another limit on the number of file descriptors than the default?
# any string will be passed to ulimit -n
#ULIMIT_N=4096
#
###############################################################################################
# Change and uncomment the variables below if your setup is different than the one by default #
###############################################################################################

#ALLOW_COREDUMP="no"

#################
# DPM variables #
#################

# - DPM Name Server host : please change !!!!!!
#DPNS_HOST=grid05.lal.in2p3.fr

# - make sure we use globus pthread model
#export GLOBUS_THREAD_MODEL=pthread
';

Readonly my $DPM_INITIAL_CONF_2 => $DPM_INITIAL_CONF_1 . '
# Duplicated line
ALLOW_COREDUMP="no"
#
# Very similar line
ALLOW_COREDUMP2="no"
';

Readonly my $DPM_INITIAL_CONF_3 => $DPM_INITIAL_CONF_1 . '
#DISKFLAGS="a list of flag"
';

Readonly my $DMLITE_INITIAL_CONF_1 => '#
# This is the Apache configuration for the dmlite DAV.
#
# The first part of the file configures all the required options common to all
# VirtualHosts. The actual VirtualHost instances are defined at the end of this file.
#

# Static content
Alias /static/ /usr/share/lcgdm-dav/
<Location "/static">
  <IfModule expires_module>
    ExpiresActive On
    ExpiresDefault "access plus 1 month"
  </IfModule>
</Location>

# Alias for the delegation
ScriptAlias /gridsite-delegation "/usr/libexec/gridsite/cgi-bin/gridsite-delegation.cgi"

# Base path for nameserver requests
<LocationMatch "^/dpm/lal\.in2p3\.fr/.*">

  # None, one or several flags
  # Write      Enable write access
  # NoAuthn    Disables user authentication
  # RemoteCopy Enables third party copies
  NSFlags Write

  # On redirect, maximum number of replicas in the URL
  # (Used only by LFC)
  NSMaxReplicas 3

  # Redirection ports
  # Two parameters: unsecure (plain HTTP) and secure (HTTPS)
  # NSRedirectPort 80 443

  # List of trusted DN (as X509 Subject).
  # This DN can act on behalf of other users using the HTTP headers:
  # X-Auth-Dn
  # X-Auth-FqanN (Can be specified multiple times, with N starting on 0, and incrementing)
  # NSTrustedDNS "/DC=ch/DC=cern/OU=computers/CN=trusted-host.cern.ch"

  # If mod_gridsite does not give us information about the certificate, this
  # enables mod_ssl to pass environment variables that can be used by mod_lcgdm_ns
  # to get the user DN.
  SSLOptions +StdEnvVars

</LocationMatch>
';


Readonly my $DPM_EXPECTED_CONF_1 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
# should the dpm daemon run?
# any string but "yes" will equivalent to "NO"
#
RUN_DPMDAEMON="no"
#
# should we run with another limit on the number of file descriptors than the default?
# any string will be passed to ulimit -n
#ULIMIT_N=4096
#
###############################################################################################
# Change and uncomment the variables below if your setup is different than the one by default #
###############################################################################################

ALLOW_COREDUMP="yes"		# Line generated by Quattor

#################
# DPM variables #
#################

# - DPM Name Server host : please change !!!!!!
#DPNS_HOST=grid05.lal.in2p3.fr

# - make sure we use globus pthread model
export GLOBUS_THREAD_MODEL=pthread		# Line generated by Quattor
';

Readonly my $DPM_EXPECTED_CONF_2 => $DPM_EXPECTED_CONF_1 . '
# Duplicated line
ALLOW_COREDUMP="yes"		# Line generated by Quattor
#
# Very similar line
ALLOW_COREDUMP2="no"
';

Readonly my $DPM_EXPECTED_CONF_3 => $DPM_EXPECTED_CONF_1 . '
DISKFLAGS="Write RemoteCopy"		# Line generated by Quattor
';

Readonly my $DMLITE_EXPECTED_CONF_1 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
#
# This is the Apache configuration for the dmlite DAV.
#
# The first part of the file configures all the required options common to all
# VirtualHosts. The actual VirtualHost instances are defined at the end of this file.
#

# Static content
Alias /static/ /usr/share/lcgdm-dav/
<Location "/static">
  <IfModule expires_module>
    ExpiresActive On
    ExpiresDefault "access plus 1 month"
  </IfModule>
</Location>

# Alias for the delegation
ScriptAlias /gridsite-delegation "/usr/libexec/gridsite/cgi-bin/gridsite-delegation.cgi"

# Base path for nameserver requests
<LocationMatch "^/dpm/lal\.in2p3\.fr/.*">

  # None, one or several flags
  # Write      Enable write access
  # NoAuthn    Disables user authentication
  # RemoteCopy Enables third party copies
NSFlags Write RemoteCopy

  # On redirect, maximum number of replicas in the URL
  # (Used only by LFC)
  NSMaxReplicas 3

  # Redirection ports
  # Two parameters: unsecure (plain HTTP) and secure (HTTPS)
  # NSRedirectPort 80 443

  # List of trusted DN (as X509 Subject).
  # This DN can act on behalf of other users using the HTTP headers:
  # X-Auth-Dn
  # X-Auth-FqanN (Can be specified multiple times, with N starting on 0, and incrementing)
  # NSTrustedDNS "/DC=ch/DC=cern/OU=computers/CN=trusted-host.cern.ch"

  # If mod_gridsite does not give us information about the certificate, this
  # enables mod_ssl to pass environment variables that can be used by mod_lcgdm_ns
  # to get the user DN.
  SSLOptions +StdEnvVars

</LocationMatch>
';

Readonly my $COND_TEST_INITIAL => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
NSFlags Write RemoteCopy
DiskFlags NoAuthn
';

Readonly my $COND_TEST_EXPECTED_1 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
NSFlags Write RemoteCopy
';

Readonly my $COND_TEST_EXPECTED_2 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
NSFlags Write RemoteCopy
#DiskFlags NoAuthn
';

Readonly my $COND_TEST_EXPECTED_3 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
DiskFlags NoAuthn
NSFlags Write RemoteCopy
';

Readonly my $NEG_COND_TEST_EXPECTED_1 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
DiskFlags NoAuthn
';

Readonly my $NEG_COND_TEST_EXPECTED_2 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
#NSFlags Write RemoteCopy
DiskFlags NoAuthn
';


Readonly my $NO_RULE_EXPECTED => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
RFIO DAEMONV3_WRMT 1
';

Readonly my $MULTI_COND_SETS_EXPECTED => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
DPNS FTRUST node1.example.com
DPNS FTRUST node2.example.com
DPNS FTRUST node4.example.com
DPNS FTRUST node3.example.com
DPNS RTRUST node1.example.com node1.example.com node2.example.com node3.example.com node4.example.com
DPNS TRUST node1.example.com node2.example.com node4.example.com node3.example.com node1.example.com
DPNS WTRUST node1.example.com node2.example.com node3.example.com node4.example.com
';


# Test rules

my %dpm_config_rules_1 = (
      "ALLOW_COREDUMP" => "allowCoreDump:dpm;".LINE_FORMAT_SH_VAR.";".LINE_VALUE_BOOLEAN,
      "GLOBUS_THREAD_MODEL" => "globusThreadModel:dpm;".LINE_FORMAT_ENV_VAR,
     );

my %dpm_config_rules_2 = (
      "ALLOW_COREDUMP" => "allowCoreDump:dpm;".LINE_FORMAT_SH_VAR.";".LINE_VALUE_BOOLEAN,
      "GLOBUS_THREAD_MODEL" => "globusThreadModel:dpm;".LINE_FORMAT_ENV_VAR,
      "DISKFLAGS" =>"DiskFlags:dpm;".LINE_FORMAT_SH_VAR.";".LINE_VALUE_ARRAY,
     );

my %dav_config_rules = (
        "NSFlags" =>"NSFlags:dav;".LINE_FORMAT_KEY_VAL.";".LINE_VALUE_ARRAY,
);

my %rules_with_conditions = (
        "NSFlags" =>"DiskFlags:dpm->NSFlags:dav;".LINE_FORMAT_KEY_VAL.";".LINE_VALUE_ARRAY,
        "DiskFlags" =>"DiskFlags:dpns->DiskFlags:dav;".LINE_FORMAT_KEY_VAL.";".LINE_VALUE_ARRAY,
);

my %rules_with_conditions_2 = (
        "NSFlags" =>"DiskFlags:dpm->NSFlags:dav;".LINE_FORMAT_KEY_VAL.";".LINE_VALUE_ARRAY,
        "DiskFlags" =>"DiskFlags:dpn->DiskFlags:dav;".LINE_FORMAT_KEY_VAL.";".LINE_VALUE_ARRAY,
);

my %rules_with_neg_conds = (
        "NSFlags" =>"!DiskFlags:dpm->NSFlags:dav;".LINE_FORMAT_KEY_VAL.";".LINE_VALUE_ARRAY,
        "DiskFlags" =>"!DiskFlags:dpns->DiskFlags:dav;".LINE_FORMAT_KEY_VAL.";".LINE_VALUE_ARRAY,
);

my %rules_no_rule = (
        "RFIO DAEMONV3_WRMT 1" => ";".LINE_FORMAT_KEY_VAL,
);

my %rules_multi_cond_sets = (
        "DPNS TRUST" => "dpm->hostlist:dpns,srmv1;".LINE_FORMAT_KEY_VAL.";".LINE_VALUE_ARRAY,
        "DPNS WTRUST" => "dpm->hostlist:dpns,srmv1;".LINE_FORMAT_KEY_VAL.";".LINE_VALUE_ARRAY.":".LINE_VALUE_OPT_UNIQUE,
        "DPNS RTRUST" => "dpm->hostlist:dpns,srmv1;".LINE_FORMAT_KEY_VAL.";".LINE_VALUE_ARRAY.":".LINE_VALUE_OPT_SORTED,
        "DPNS FTRUST" => "dpm->hostlist:dpns,srmv1;".LINE_FORMAT_KEY_VAL.";".LINE_VALUE_ARRAY.":".LINE_VALUE_OPT_SINGLE,
);

my %rules_always = (
        "NSFlags" => "ALWAYS->NSFlags:dav;".LINE_FORMAT_KEY_VAL.";".LINE_VALUE_ARRAY,
        "DiskFlags" => "DiskFlags:dav;".LINE_FORMAT_KEY_VAL.";".LINE_VALUE_ARRAY,
);

# Option sets

my $dpm_options = {dpm => {allowCoreDump => 1,
                           globusThreadModel => "pthread",
                           fastThreads => 200,
                           DiskFlags => [ "Write", "RemoteCopy" ],
                          },
                   dpns => {hostlist => ['node1.example.com', 'node2.example.com']},
                   srmv1 => {hostlist => ['node4.example.com', 'node3.example.com', 'node1.example.com']}};

my $dmlite_options = {dav => {NSFlags => [ "Write", "RemoteCopy" ],
                              DiskFlags => [ "NoAuthn" ],
                             }};


my $all_options = {%$dpm_options, %$dmlite_options};


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

set_file_contents($DPM_CONF_FILE,$DPM_INITIAL_CONF_1);


# Test  simple variable substitution
set_file_contents($DPM_CONF_FILE,$DPM_INITIAL_CONF_1);
my $fh = CAF::FileEditor->open($DPM_CONF_FILE, log => $this_app);
ok(defined($fh), $DPM_CONF_FILE." was opened");
$changes = $fh->updateFile(\%dpm_config_rules_1,
                           $dpm_options);
is("$fh", $DPM_EXPECTED_CONF_1, $DPM_CONF_FILE." has expected contents (config 1)");
$fh->close();


# Test potentially ambiguous config (duplicated lines, similar keywords)
set_file_contents($DPM_CONF_FILE,$DPM_INITIAL_CONF_2);
my $fh = CAF::FileEditor->open($DPM_CONF_FILE, log => $this_app);
ok(defined($fh), $DPM_CONF_FILE." was opened");
$changes = $fh->updateFile(\%dpm_config_rules_1,
                           $dpm_options);
is("$fh", $DPM_EXPECTED_CONF_2, $DPM_CONF_FILE." has expected contents (config 2)");
$fh->close();


# Test array displayed as list
set_file_contents($DPM_CONF_FILE,$DPM_INITIAL_CONF_3);
my $fh = CAF::FileEditor->open($DPM_CONF_FILE, log => $this_app);
ok(defined($fh), $DPM_CONF_FILE." was opened");
$changes = $fh->updateFile(\%dpm_config_rules_2,
                           $dpm_options);
is("$fh", $DPM_EXPECTED_CONF_3, $DPM_CONF_FILE." has expected contents (config 3)");
$fh->close();


# Test 'keyword value" format (a la Apache)
set_file_contents($DMLITE_CONF_FILE,$DMLITE_INITIAL_CONF_1);
my $fh = CAF::FileEditor->open($DMLITE_CONF_FILE, log => $this_app);
ok(defined($fh), $DMLITE_CONF_FILE." was opened");
$changes = $fh->updateFile(\%dav_config_rules,
                           $dmlite_options);
is("$fh", $DMLITE_EXPECTED_CONF_1, $DMLITE_CONF_FILE." has expected contents");
$fh->close();


# Test rule conditions

set_file_contents($DMLITE_CONF_FILE,'');
my $fh = CAF::FileEditor->open($DMLITE_CONF_FILE, log => $this_app);
ok(defined($fh), $DMLITE_CONF_FILE." was opened");
$changes = $fh->updateFile(\%rules_with_conditions,
                           $all_options);
is("$fh", $COND_TEST_EXPECTED_1, $DMLITE_CONF_FILE." has expected contents (rules with conditions)");
$fh->close();

set_file_contents($DMLITE_CONF_FILE,'');
my $fh = CAF::FileEditor->open($DMLITE_CONF_FILE, log => $this_app);
ok(defined($fh), $DMLITE_CONF_FILE." was opened");
$changes = $fh->updateFile(\%rules_with_neg_conds,
                           $all_options);
is("$fh", $NEG_COND_TEST_EXPECTED_1, $DMLITE_CONF_FILE." has expected contents (rules with negative conditions)");
$fh->close();

set_file_contents($DMLITE_CONF_FILE,$COND_TEST_INITIAL);
my $fh = CAF::FileEditor->open($DMLITE_CONF_FILE, log => $this_app);
ok(defined($fh), $DMLITE_CONF_FILE." was opened");
$changes = $fh->updateFile(\%rules_with_conditions,
                           $all_options);
is("$fh", $COND_TEST_INITIAL, $DMLITE_CONF_FILE." has expected contents (initial contents, rules conditions with non existent attribute)");
$fh->close();

set_file_contents($DMLITE_CONF_FILE,$COND_TEST_INITIAL);
my $fh = CAF::FileEditor->open($DMLITE_CONF_FILE, log => $this_app);
ok(defined($fh), $DMLITE_CONF_FILE." was opened");
$changes = $fh->updateFile(\%rules_with_conditions_2,
                           $all_options);
is("$fh", $COND_TEST_INITIAL, $DMLITE_CONF_FILE." has expected contents (initial contents, rules conditions with non existent option set)");
$fh->close();

my %parser_options;
$parser_options{remove_if_undef} = 1;
set_file_contents($DMLITE_CONF_FILE,$COND_TEST_INITIAL);
my $fh = CAF::FileEditor->open($DMLITE_CONF_FILE, log => $this_app);
ok(defined($fh), $DMLITE_CONF_FILE." was opened");
$changes = $fh->updateFile(\%rules_with_conditions,
                           $all_options,
                           \%parser_options);
is("$fh", $COND_TEST_EXPECTED_2, $DMLITE_CONF_FILE." has expected contents (initial contents, rules conditions, parser options)");
$fh->close();

set_file_contents($DMLITE_CONF_FILE,$COND_TEST_INITIAL);
my $fh = CAF::FileEditor->open($DMLITE_CONF_FILE, log => $this_app);
ok(defined($fh), $DMLITE_CONF_FILE." was opened");
$changes = $fh->updateFile(\%rules_with_neg_conds,
                           $all_options,
                           \%parser_options);
is("$fh", $NEG_COND_TEST_EXPECTED_2, $DMLITE_CONF_FILE." has expected contents (initial contents, rules with negative conditions, parser options)");
$fh->close();

set_file_contents($DMLITE_CONF_FILE,'');
my $fh = CAF::FileEditor->open($DMLITE_CONF_FILE, log => $this_app);
ok(defined($fh), $DMLITE_CONF_FILE." was opened");
$changes = $fh->updateFile(\%rules_always,
                           $dmlite_options);
is("$fh", $COND_TEST_EXPECTED_3, $DMLITE_CONF_FILE." has expected contents (always_rules_only not set)");
$fh->close();

$parser_options{always_rules_only} = 1;
set_file_contents($DMLITE_CONF_FILE,'');
my $fh = CAF::FileEditor->open($DMLITE_CONF_FILE, log => $this_app);
ok(defined($fh), $DMLITE_CONF_FILE." was opened");
$changes = $fh->updateFile(\%rules_always,
                           $dmlite_options,
                           \%parser_options);
is("$fh", $COND_TEST_EXPECTED_1, $DMLITE_CONF_FILE." has expected contents (always_rules_only set)");
$fh->close();


# Rule with only a keyword
set_file_contents($DPM_SHIFT_CONF_FILE,'');
my $fh = CAF::FileEditor->open($DPM_SHIFT_CONF_FILE, log => $this_app);
ok(defined($fh), $DPM_SHIFT_CONF_FILE." was opened");
$changes = $fh->updateFile(\%rules_no_rule,
                           $dpm_options);
is("$fh", $NO_RULE_EXPECTED, $DPM_SHIFT_CONF_FILE." has expected contents (keyword only)");
$fh->close();


# Rule with multiple condition sets and multiple-word keyword
set_file_contents($DPM_SHIFT_CONF_FILE,'');
my $fh = CAF::FileEditor->open($DPM_SHIFT_CONF_FILE, log => $this_app);
ok(defined($fh), $DPM_SHIFT_CONF_FILE." was opened");
$changes = $fh->updateFile(\%rules_multi_cond_sets,
                           $dpm_options);
is("$fh", $MULTI_COND_SETS_EXPECTED, $DPM_SHIFT_CONF_FILE." has expected contents (multiple condition sets)");
$fh->close();


Test::NoWarnings::had_no_warnings();
