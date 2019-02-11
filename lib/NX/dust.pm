package NX::dust;

use strict;
use warnings;
use v5.10;
use Number::Bytes::Human;
use Capture::Tiny qw( capture );

# ABSTRACT: directory dusting
# VERSION

=head1 SYNOPSIS

 % dust

=head1 DESCRIPTION

Calculate the size of all child directories and list
in order of size, in human notation.

=cut

sub main
{
  my $class = shift;
  local @ARGV = @_;
  
  my $human = new Number::Bytes::Human(bs => 1024);

  my $directory_only = 0;

  my @list;

  while(my $arg = shift)
  {
    if($arg eq '-d')
    {
      $directory_only = 1;
    }
    elsif($arg eq '--')
    {
      push @list, @ARGV;
     last;
    }
   elsif($arg =~ /^-/)
    { 
      print STDERR "unknown option: $arg\n";
      exit 2;
    }
    else
    {
      push @list, $arg;
    }
  }

  unless(@list > 0)
  {
    opendir(my $dh, ".") || die "unable to read . $!";
    @list = grep !/^\.\.?$/, readdir($dh);
    closedir $dh;
    @list = grep { -d } @list if $directory_only;
  }

  my $du = $^O =~ /^(darwin|solaris|netbsd)$/ ? 'gdu' : 'du';

  my($out, $err) = capture {
    system $du, '-B' => 1, '-s', '-c', @list;
  };

  my %list = map { (split "\t")[1,0]; } split "\n", $out;

  foreach my $thing (sort { $list{$a} <=> $list{$b} } keys %list)
  {
    print $human->format($list{$thing}), "\t$thing\n";
  }
}

1;
