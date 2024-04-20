package URI::Template::Extract 0.01;
use 5.020;
use Moo 2;

use experimental 'signatures';
use stable 'postderef';
use Exporter 'import';

our @EXPORT_OK = (qw(extract_parameters));

=head1 SYNOPSIS

  my $extractor = URI::Template::Extract->new(
      template => 'https://{env}.example.com/api/v1'
  );
  my $info = $extractor->extract( 'https://dev.example.com/api/v1/list' );
  say $info->{env}; # "dev"
  say $info->{extra_path}; # "/list"

=cut

has 'template' => (
    is => 'ro',
);

has 'compiled_template' => (
    is => 'lazy',
    default => sub ($self) {
        $self->compile_template( $self->template );
    },
);

sub compile_template( $self, $template = $self->template ) {
    # First, split the string into variable parts in {...}
    # and constant parts (the rest)
    my @parts = split /(?=\{)|(?<=\})/, $template;

    # Convert all variable parts into named capturing groups
    # and quote the constant parts
    @parts = map { /^\{(.*)\}/ ? qr/(?<$1>.*?)/
                         : qr/\Q$_\E/
                 } @parts;
    push @parts, qr!(?<extra_path>/.*?)?\z!;
    return join "", @parts;
}

sub extract( $self, $url ) {
    my $regexp = $self->compiled_template;
    if( $url =~ /\A$regexp\z/ ) {
        return {
            %+
        };
    } else {
        # no match
        return
    }
}

sub extract_parameters( $template, $url ) {
    __PACKAGE__->new( template => $template )->extract( $url );
}

1;
