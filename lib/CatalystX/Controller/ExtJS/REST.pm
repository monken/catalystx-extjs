package CatalystX::Controller::ExtJS::REST;

use strict;
use warnings;


use base qw(Catalyst::Controller::REST);
#with 'Catalyst::Component::InstancePerContext';

use Config::Any;
use Scalar::Util qw/ weaken /;
use Carp qw/ croak /;

use HTML::FormFu::ExtJS;
use HTML::FormFu::Util qw( _merge_hashes );
use Path::Class;
use HTML::Entities;
use JSON qw(encode_json);

use Lingua::EN::Inflect;

our $VERSION = '0.01';

use Moose;

has '_extjs_config' => ( is => 'rw', isa => 'HashRef', builder => '_extjs_config_builder', lazy => 1 );

sub _extjs_config_builder {
    my $self = shift;
    my $c = $self->_application;
    my $default_rs_method = lc($self->default_resultset);
    $default_rs_method =~ s/::/_/g;
    
    my $defaults = { model_config => { schema => 'DBIC', resultset => $self->default_resultset },
                     form_base_path => [qw(root forms)],
                     list_base_path => [qw(root lists)],
                     default_rs_method => 'extjs_rest_'.$default_rs_method };
    my $self_config   = $self->config || {};
    my $parent_config = $c->config->{'ControllerX::ExtJS::REST'} || {};

    # merge hashes with right hand precedence
    my $merged_config = $self->merge_config_hashes( $defaults, $self_config );
    $merged_config = $self->merge_config_hashes( $merged_config, $parent_config );

    return $merged_config;
    
}

sub is_extjs_upload {
    my ( $self, $c ) = @_;
    return ( $c->req->param('x-requested-by') && $c->req->param('x-requested-by') eq "ExtJS"
          && $c->req->header('Content-Type') && $c->req->header('Content-Type') =~ /^multipart\/form-data/ );
}

sub default_resultset {
    my ($self, $c) = @_;
    my $class = ref $self;
    my $prefix;
    
    # Copied from Catalyst::Utils
    if($class =~ /^.+?::([MVC]|Model|View|Controller)::(.+)$/ ) {
        $prefix = $2;
    }
    return $prefix;
}

sub list : Chained('/') NSListPathPart Args {
    my ( $self, $c ) = @_;

    my $form = $self->get_form($c);
    $form->load_config_file($self->list_base_file);
    my $config = $form->model_config;
    croak "Need resultset and schema" unless($config->{resultset} && $config->{schema});
    my $model = join('::', $config->{schema}, $config->{resultset});

    my $rs = $c->model($model);
    $rs = $self->paging_rs($c, $form, $rs);
    my @args = @{$c->req->args};
    unshift(@args, $self->_extjs_config->{default_rs_method});
    for my $rs_method (@args) {
        next unless($rs_method);
        if($rs_method && $rs_method ne "all" && DBIx::Class::ResultSet->can($rs_method)) {
            $c->log->warn('Possibly malicious method "'.$rs_method.'" on resultset '.$rs_method.' has not been called');
            next;
        }
        my ($m, @params) = split(/,/, $rs_method);
        if($rs->can($m)) {
            if($c->debug) {
                my $debug = qq(Calling resultset method $m);
                $debug .= q( with arguments ').join(q(', '), @params).q(') if(@params);
                $c->log->debug($debug);
            }
            $rs = $rs->$m($c,@params);
        } elsif($c->debug) {
            $c->log->debug(qq(Resultset method $m could not be found));
        }
    }
    
    my $grid_data = $form->grid_data([$rs->all]);
    my $count = $rs->search(undef, { rows => undef, offset => undef })->count;
    $grid_data->{results} = $count;
    
    $self->status_ok( $c, entity => $grid_data);
    # list
}

sub paging_rs : Private {
    my ($self, $c, $form, $rs) = @_;
    my $params = $c->req->params;
    
    my $start = abs(int($params->{start} || 0));
    
    my $limit = abs(int($params->{limit} || 0));

    return $rs if($start == 0 && $limit == 0);

    my @direction = grep { $_ eq (lc($params->{dir}) || 'asc') } qw(asc desc);
    my $direction = q{-}.(shift @direction);
    
    my $sort = $params->{sort} || undef;
    
    undef $sort unless($form->get_all_element({ nested_name => $sort }));
    
    my $paged = $rs->search(undef, { offset => $start, rows => $limit || undef});
    $paged = $paged->search(undef, { order_by => { $direction => $sort } })
      if $sort;
    return $paged;
}

=head2 object

REST Action which returns works with single model entites.

=cut

sub object : Chained('/') NSPathPart Args ActionClass('REST') {
    my ( $self, $c, $id ) = @_;

        
    croak $self->base_file." cannot be found" unless(-e $self->base_file);
    
    my $config = Config::Any->load_files( {files => [ $self->base_file ], use_ext => 1, flatten_to_hash => 0 } );
    $config = { %{$self->_extjs_config->{model_config}}, %{$config->{$self->base_file}->{model_config} || {}} };
    $config->{resultset} ||= $self->default_resultset;
    croak "Need resultset and schema" unless($config->{resultset} && $config->{schema});
    $c->stash->{extjs_formfu_model_config} = $config;
    
    my $object = $c->model(join('::', $config->{schema}, $config->{resultset}));
        
    if(my $rs = $self->_extjs_config->{default_rs_method}) {
        if($object->can($rs)) {
            $c->log->debug(qq(Calling default resultset method $rs)) if($c->debug);
            $object = $object->$rs($c);
        } elsif($c->debug) {
            $c->log->debug(qq(Default resultset method $rs cannot be found));
        }
    }

    # Get row object
    my $method = $config->{find_method} || 'find';
    if (defined $id && defined $object) {
        $object = $object->$method($id);
        $c->stash->{object} = $object;
    }
}

=head2 object_PUT

REST Action to update a single model entity with a PUT request.

=cut

sub object_PUT {
    my ( $self, $c ) = @_;
    my $object = $c->stash->{object};
    my $config = $c->stash->{extjs_formfu_model_config};

    # Check if row object exists
    if(!$c->stash->{object}) {
        $self->status_not_found($c, message => 'Object could not be found.');
        return;
    }

    my $form = $self->get_form($c);
    $form->load_config_file( $self->path_to_forms('put') );

    $self->object_PUT_or_POST($c, $form, $object);
    
    $form->process( $c->req );
    
    if ( $form->submitted_and_valid ) {
        my $row = $form->model->update($object);
        $self->handle_uploads($c, $row, $form);

        my $response = (defined $config->{respond_with_model_values}
                && $config->{respond_with_model_values})
            ? $form->form_data( $row )
            : $form->validation_response;

        $self->status_ok( $c, entity => $response );
    }
    else {
        $self->status_ok( $c, entity => $form->validation_response );
    }
}

sub object_PUT_or_POST {
    my ($self, $c, $form, $object) = @_;
    
    # the following lines will be obsolete with the new FormFu::Model::DBIC release
    # a model_config ignore_if_empty will be introduced
    
    foreach my $upload (@{$form->get_all_elements({type => "File"})}) {
        $form->remove_element($upload)
          unless($c->req->param($upload->nested_name));
    }
    foreach my $password (@{$form->get_all_elements({type => "Password"})}) {
        $form->remove_element($password)
          if($c->req->param($password->nested_name) eq ""); # "0" might be a valid password
    }

}

=head2 object_POST

REST Action to create a single model entity with a POST request.

=cut

sub object_POST {
    my ( $self, $c ) = @_;

    my $config = $c->stash->{extjs_formfu_model_config};

    my $form = $self->get_form($c);
    $form->load_config_file( $self->path_to_forms('post') );

    $self->object_PUT_or_POST($c, $form);

    $form->process( $c->req );

    if ( $form->submitted_and_valid ) {
        my $row = $form->model->create;
        $self->handle_uploads($c, $row, $form);

        my $response = (defined $config->{respond_with_model_values}
                && $config->{respond_with_model_values})
            ? $form->form_data( $row )
            : $form->validation_response;

        $self->status_created(
            $c,
            location => $c->uri_for( '', $row->id ),
            entity   => $response
        );
    }
    else {
        $self->status_ok( $c, entity => $form->validation_response );
    }

}

=head2 object_GET

REST Action to get the data of a single model entity with a GET request.

=cut

sub object_GET {
    my ( $self, $c ) = @_;
        
    my $form = $self->get_form($c);
    $form->load_config_file( $self->path_to_forms('get') );

    my $config = $c->stash->{extjs_formfu_model_config};

    $form->process( $c->req );
    
    if($c->stash->{object}) {
        $self->status_ok( $c, entity => $form->form_data( $c->stash->{object} ) );
    } else {
        $self->status_not_found($c, message => 'Object could not be found.');
    }
}

=head2 object_DELETE

REST Action to delete a single model entity with a DELETE request.

=cut

sub object_DELETE {
    my ( $self, $c ) = @_;
    if($c->stash->{object}) {
        $c->stash->{object}->delete;
        $self->status_ok( $c, entity => { message => "Object has been deleted" } );
    } else {
        $self->status_not_found($c, message => 'Object could not be found.');
    }
}

=head2 path_to_forms

Returns the path to the specific form config file or the default form config
file if the specfic one can not be found.

=cut

sub path_to_forms {
    my $self = shift;
    my $file = Path::Class::File->new($self->base_path,  (shift) . '.yml');
    return -e $file ? $file : $self->base_file;
}

=head2 base_path

Returns the path in which form config files will be searched.

=cut

sub base_path {
    my $self = shift;
    return Path::Class::Dir->new( @{$self->_extjs_config->{form_base_path}}, split( /\//, $self->action_namespace ) );
}

=head2 base_file

Returns the path to the default form config file.

=cut

sub base_file {
    my $self = shift;
    my @path = split( /\//, $self->action_namespace );
    return $self->base_path->parent->file((pop @path) . '.yml');
}

=head2 list_base_path

Returns the path in which form config files for grids will be searched.

=cut

sub list_base_path {
    my $self = shift;
    return Path::Class::Dir->new( @{$self->_extjs_config->{list_base_path}}, split( /\//, $self->action_namespace ) );
}

=head2 list_base_file

Returns the path to the specific form config file for grids or the default
form config file if the specfic one can not be found.

=cut

sub list_base_file {
    my $self = shift;
    my @path = split( /\//, $self->action_namespace );
    my $file = $self->list_base_path->parent->file((pop @path) . '.yml');
    return -e $file ? $file : $self->base_file;
}

sub get_form {
    my ($self, $c) = @_;
    #return $self->_form if($self->_form);
    my $form = HTML::FormFu::ExtJS->new();
    $form->query_type('Catalyst');
    my $model_stash = $self->_extjs_config->{model_stash};
    $model_stash->{schema} ||= "DBIC";
    for my $model ( keys %$model_stash ) {
            $form->stash->{$model} = $c->model( $model_stash->{$model} );
    }
    $form->model_config($self->_extjs_config->{model_config});
    return $form;
}

sub handle_uploads {
    my ($self, $c, $row, $form) = @_;
    my $uploads;
    while(my ($k, $v) = each %{$c->req->uploads}) {
        next unless $form->get_field($k);
        $c->log->debug("Cannot handle multiple uploads per field") if($c->debug && ref $v eq "ARRAY");
        $row->$k($v->fh);
    }
    $row->update;
}


sub begin : ActionClass('+CatalystX::Action::ExtJS::Deserialize') {
    my ( $self, $c ) = @_;
    $self->next::method($c);
}

sub end : ActionClass('Serialize') {
    my ( $self, $c ) = @_;
    $self->next::method($c);
    if ( $self->is_extjs_upload($c) ) {
        my $stash_key = (
              $self->config->{'serialize'}
            ? $self->config->{'serialize'}->{'stash_key'}
            : $self->config->{'stash_key'}
          )
          || 'rest';
        my $output;
        eval { $output = JSON->new->encode( $c->stash->{$stash_key} ); };

        $c->res->content_type('text/html');
        $c->res->output( encode_entities($output) );
    }
}

sub _parse_NSPathPart_attr {
    my ( $self, $c ) = @_;
    return ( PathPart => $self->action_namespace );
}


sub _parse_NSListPathPart_attr {
    my ( $self, $c ) = @_;
    if($self->config->{list_namespace}) {
        return ( PathPart => $self->config->{list_namespace} )
    } else {
        my @path = split( /\//, $self->action_namespace );
        $path[-1] = Lingua::EN::Inflect::PL(my $name = $path[-1]);
        $path[-1] = "list_".$path[-1]
          if($name eq $path[-1]);
    
        return ( PathPart => join('/', @path) );
    }
}

1;

__END__

=head1 NAME

CatalystX::Controller::ExtJS::REST

=head1 SYNOPSIS

=head1 CONFIGURATION

Local configuration:
  
  __PACKAGE__->config({ ... });  


Global configuration for all controllers which use CatalystX::Controller::ExtJS::REST:

  MyApp->config( {
    CatalystX::Controller::ExtJS::REST => 
      { key => value}
  } );

=head2 find_method

Use a different method when looking for existing model rows.

Defaults to 'find'.

=head2 respond_with_model_values

Get the values that are send back to ExtJS if a valid form is submitted
from model.

This is usefull if your DBIC clases do some post processing, like setting
IDs or UUIDs/GUIDs or calculating some values, to ensure that the data,
which is send back to the user is syncronized with the database.

Defaults to false.

=head2 default_rs_method

This resultset method is called on every request. This is useful if you want to 
restrict the resultset, e. g. only find objects which are associated to the
current user.

Nothing is called if the specified method does not exist.

This defaults to C<extjs_rest_[controller namespace]>.

A controller C<MyApp::Controller::User> expects a resultset method
C<extjs_rest_user>.


=head2 form_base_path

Defaults to C<root/forms>

=head2 list_base_path

Defaults to C<root/lists>

=head2 model_config

=head3 schema

Defaults to C<DBIC>

=head3 resultset

Defaults to L</default_resultset>

=head2 namespace

Defaults to L<Catalyst::Controller/namespace>

=head2 list_namespace

Defaults to the plural form of L</namespace>. If this is the same as L</namespace> C<list_> is prepended.


=head1 LIMITATIONS

This module is limited to L<HTML::FormFu> as form processing engine,
L<DBIx::Class> as ORM and L<Catalyst> as web application framework.



=head1 USAGE

=head2 Required Files

Considering you create controller like this:

  package MyApp::Controller::User;
  
  use base 'CatalystX::Controller::ExtJS::REST';
  
  1;
  
Then you will want to create the following files:

  root/
       forms/
             user.yml
             user/
                  get.yml
                  post.yml
                  put.yml
       lists/
             user.yml

Only C<root/forms/user.yml> is required. All other files must not exists. This controller
will fall back to the so called base file for all requests.

This controller tries to guess the correct model and resultset. The model defaults
to C<DBIC> and the resultset is derived from the name of the controller.
In this example we look for the resultset C<< $c->model('DBIC::User') >>.

You can override these values in the form config files:

  # root/forms/user.yml
  ---
    elements:
      - name: username
      - name: password
      - name: name
      - name: forename

  # root/forms/user.yml (exactly the same as the above)
  ---
    model_config:
      resultset: User
      schema: DBIC
    elements:
      - name: username
      - name: password
      - name: name
      - name: forename
      
  # root/forms/user/get.yml and friends
  ---
    load_config_file: root/forms/user.yml

Now you can fire up your Catalyst app and you should see two new chained actions:

  Loaded Chained actions:
  ...
  | /users/...                          | /user/list
  | /user/...                           | /user/object
    
You can access L<http://localhost:3000/users> to get a list of users, which can be used
to feed an ExtJS grid. If you access this URL with your browser you'll get a HTML 
representation of all users. If you access using a XMLHttpRequest using ExtJS the returned
value will be a valid JSON string. Listing objects is very flexible and can easily extended.
Any more attributes you add to the url will result in a call to the corresponding resultset.

  # http://localhost:3000/users/active/
  
  $c->model('DBIC::Users')->active($c)->all;
  
As you can see, the Catalyst context object is passed as first parameter.
You can even supply arguments to that method using a komma separated list:

  # http://localhost:3000/users/active,arg1,arg2/
  
  $c->model('DBIC::Users')->active($c, 'arg1', 'arg2')->all;

You can chain those method calls to any length. You cannot access resultset method which are
inherited from L<DBIx::Class::ResultSet>, except C<all>. This is a security restriction because
an attacker could call C<http://localhost:3000/users/delete> which will lead to 
C<< $c->model('DBIC::Users')->delete >>. This will remove all rows from C<DBIC::Users>.

To define a default resultset method which gets called every time the controller hits the
result table, set:

  __PACKAGE__->config({default_rs_method => 'restrict'});

This will lead to the following chain:

  # http://localhost:3000/users/active,arg1,arg2/
  
  $c->model('DBIC::Users')->restrict($c)->active($c, 'arg1', 'arg2')->all;

  # and even with GET, POST and PUT
  # http://localhost:3000/user/1234
  
  $c->model('DBIC::Users')->restrict($c)->find(1234);

To create, delete and modify C<user> objects, simply C<POST>, C<DELETE> or C<PUT> to
the url C</user>. C<POST> and C<DELETE> require that you add the id to that url,
e. g. C</user/1234>.

=head2 Configuration options

=over

=item find_method
The method to call on the resultset to get an existing row object.
This can be set to the name of a custom function function which is defined with the (custom) resultset class.
It needs to take the primary key as first parameter.
Defaults to 'find'.

To create and use a custom resultset method you can subclass L<DBIx::Class::ResultSet>,
require that module in your db table definition classes and tell DBIC to use it in that module by calling
C<< __PACKAGE__->resultset_class('Your::Custom::Resultset') >>.

=back

=head2 Handling Uploads

This module handles your uploads. If there is an upload and the name of that field
exists in you form config, the column is set to an L<IO::File> object. You need to
handle this on the model side because storing a filehandle will most likely fail.

There a modules out there which can help you with that. Have a look at
L<DBIx::Class::InflateColumn::FS>. L<DBIx::Class:InflateColumn::File> will not work as this
module expects a hash with the file handler and the file name set. But you can
still overwrite L</handle_uploads> to your needs.

As an upload field is a regular field it gets set twice. First the filename is set
and C<< $row->update >> is called. This is entirely handled by L<HTML::FormFu::Model::DBIC>.
After that L</handle_uploads> is called which sets the value of a upload field
to the corresponding L<IO::File> object. Make sure you test for that, if you plan to
inflate such a column.

If you want to handle uploads yourself, overwrite L</handle_uploads>
  
  sub handle_uploads {
      my ($self, $c, $row) = @_;
      if(my $file = c->req->uploads->{upload}) {
          $file->copy_to('yourdestination/'.$filename);
          $row->upload($file->filename);
      }
  }

But this should to be part of the model actually.

Since you cannot upload files with an C<XMLHttpRequest> ExtJS creates an iframe and issues
a C<POST> request in there. If you need to make a C<PUT> request you have to tunnel the
desired method using a hidden field, by using the C<params> config option of 
C<Ext.form.Action.Submit> or C<extraParams> in C<Ext.Ajax.request>. The name of that
parameter has to be C<x-tunneled-method>.

Make sure you do not include a file field in your C<GET> form definition. It will
cause a security error in your browser because it is not allowed set the value of
a file field.

=head1 PUBLIC METHODS

=head2 get_form

Returns a new L<HTML::FormFu::ExtJS> class, sets the model config options and the
request type to C<Catalyst>.

=head2 list

List Action which returns the data for a ExtJS grid.

=head2 object_PUT_or_POST

Inernal method for REST Actions to handle the update of single model entity
with PUT or POST requests.

This method is called before the form is being processed. This allows to add or
remove form elements.

=head2 handle_uploads

Handles uploaded files by assigning the filehandle to the column accessor of
the DBIC row object.

=head2 is_extjs_upload

Returns true if the current request looks like a request from ExtJS and has
multipart form data, so usually an upload. This requires that you add a C<x-requested-by> parameter to your
form which has the value C<ExtJS>. This can be done either by adding a hidden form field,
by using the C<params> config option of ExtJS C<Ext.form.Action.Submit> or C<extraParams> in C<Ext.Ajax.request>.

=head2 default_resultset

Determines the default name of the resultset class from the Model / View or
Controller class.


=head1 PRIVATE METHODS

These methods are private. Please don't overwrite those unless you know what you are doing.

=head2 begin

Run this code before any action in this controller. It sets the C<ActionClass> to L<CatalystX::Action::ExtJS::Deserialize>.
This C<ActionClass> makes sure that no deserialization happens if the body's content is a file upload.

=cut

=head2 end

If the request contains a file upload field, extjs expects the json response to be serialized and 
returned in a document with the C<Content-type> set to C<text/html>.

=head2 _parse_NSPathPart_attr

=head2 _parse_NSListPathPart_attr

=head2 _extjs_config

This accessor contains the configuration options for this controller. It is created by merging
C<__PACKAGE__->config> with the default values.
